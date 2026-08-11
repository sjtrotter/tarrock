namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using System.IO;
    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine;
    using UnityEngine.SceneManagement;

    /// <summary>
    /// Editor command that swaps the Cliff's stand-in foliage onto the <c>Tarrock/FoliageWind</c>
    /// shader so the region's plants can sway once its Arcana is unbound (art-audio.md §The
    /// world-state is the art direction; the sway itself is driven at runtime by
    /// <see cref="Tarrock.Regions.RegionWind"/> via the global <c>_TarrockWindStrength</c>).
    ///
    /// <para>
    /// Swap discipline (art-audio.md §Current build): the vendored KayKit materials are NEVER edited
    /// in place. This tool creates wind-variant COPIES under <c>Assets/_Project/Materials/Wind/</c>,
    /// copies each source's base map / colour / cutoff onto the copy, and re-points the scene's
    /// renderers at the copies — leaving the ThirdParty assets untouched.
    /// </para>
    ///
    /// <para>
    /// Scope: the current selection if any GameObjects are selected, otherwise every living-foliage
    /// object in the active scene, matched by the <see cref="CliffHexGenerator"/> naming
    /// (<c>tree_*</c>, <c>bush_*</c>, <c>tuft_*</c>). The dead tree is deliberately excluded — nothing
    /// grows in its shade (MQ00), so it does not gain wind.
    /// </para>
    ///
    /// <para>Idempotent: a renderer already on the FoliageWind shader is skipped, and re-running
    /// reuses the existing wind-variant asset rather than creating a second copy.</para>
    /// </summary>
    public static class FoliageWindInstaller
    {
        private const string FoliageWindShaderName = "Tarrock/FoliageWind";
        private const string WindMaterialDir = "Assets/_Project/Materials/Wind";
        private const string WindMaterialSuffix = "_Wind";

        // CliffHexGenerator names living foliage with these prefixes (tree_*, bush_tall_*/bush_short_*,
        // tuft_*). The dead tree and the soft foliage-drag triggers are intentionally not included.
        private static readonly string[] FoliagePrefixes = { "tree_", "bush_", "tuft_" };

        // URP/Lit + legacy property ids we preserve when cloning onto the wind shader.
        private static readonly int BaseMapId = Shader.PropertyToID("_BaseMap");
        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private static readonly int ColorId = Shader.PropertyToID("_Color");
        private static readonly int CutoffId = Shader.PropertyToID("_Cutoff");
        private static readonly int AlphaClipId = Shader.PropertyToID("_AlphaClip");

        private const string AlphaTestKeyword = "_ALPHATEST_ON";
        private const string WindAlphaClipKeyword = "_ALPHACLIP_ON";

        [MenuItem("Tarrock/Setup/Install Foliage Wind")]
        public static void Install()
        {
            Shader windShader = Shader.Find(FoliageWindShaderName);
            if (windShader == null)
            {
                Debug.LogError(
                    $"[Tarrock] Shader '{FoliageWindShaderName}' not found — cannot install foliage wind. " +
                    "Ensure Assets/_Project/Shaders/FoliageWind.shader has imported without errors.");
                return;
            }

            List<Renderer> renderers = CollectFoliageRenderers();
            if (renderers.Count == 0)
            {
                Debug.LogWarning(
                    "[Tarrock] No living-foliage renderers found. Select foliage objects, or open a scene " +
                    "with CliffHexGenerator foliage (tree_* / bush_* / tuft_*), then re-run.");
                return;
            }

            Directory.CreateDirectory(WindMaterialDir);

            // Source material -> its wind variant, deduped so shared atlas materials clone once.
            var variants = new Dictionary<Material, Material>();
            int swappedSlots = 0;
            int createdVariants = 0;

            foreach (Renderer renderer in renderers)
            {
                Material[] shared = renderer.sharedMaterials;
                bool changed = false;

                for (int i = 0; i < shared.Length; i++)
                {
                    Material source = shared[i];
                    if (source == null || source.shader == windShader)
                    {
                        continue; // already a wind material (idempotent) or an empty slot
                    }

                    if (!variants.TryGetValue(source, out Material variant))
                    {
                        variant = GetOrCreateWindVariant(source, windShader, ref createdVariants);
                        variants.Add(source, variant);
                    }

                    if (variant != null && shared[i] != variant)
                    {
                        shared[i] = variant;
                        changed = true;
                        swappedSlots++;
                    }
                }

                if (changed)
                {
                    renderer.sharedMaterials = shared;
                    EditorUtility.SetDirty(renderer);
                }
            }

            AssetDatabase.SaveAssets();
            MarkActiveSceneDirty();

            Debug.Log(
                $"[Tarrock] Foliage wind installed: {swappedSlots} renderer material slot(s) swapped across " +
                $"{renderers.Count} foliage object(s); {createdVariants} wind-variant material(s) created/updated " +
                $"under {WindMaterialDir}. Add a Tarrock.Regions.RegionWind to the scene (set its region " +
                "WS_* id) so the sway rises when the region unbinds.");
        }

        private static List<Renderer> CollectFoliageRenderers()
        {
            var result = new List<Renderer>();

            // Selection wins when the director has hand-picked objects to convert.
            if (Selection.gameObjects.Length > 0)
            {
                foreach (GameObject selected in Selection.gameObjects)
                {
                    result.AddRange(selected.GetComponentsInChildren<Renderer>(true));
                }

                return result;
            }

            // Otherwise scan the active scene for CliffHexGenerator-named living foliage.
            Scene scene = SceneManager.GetActiveScene();
            if (!scene.IsValid())
            {
                return result;
            }

            foreach (GameObject root in scene.GetRootGameObjects())
            {
                CollectByName(root.transform, result);
            }

            return result;
        }

        private static void CollectByName(Transform current, List<Renderer> into)
        {
            if (IsFoliageName(current.name))
            {
                into.AddRange(current.GetComponentsInChildren<Renderer>(true));
                return; // whole subtree captured; no need to descend for more matches
            }

            for (int i = 0; i < current.childCount; i++)
            {
                CollectByName(current.GetChild(i), into);
            }
        }

        private static bool IsFoliageName(string name)
        {
            foreach (string prefix in FoliagePrefixes)
            {
                if (name.StartsWith(prefix, System.StringComparison.Ordinal))
                {
                    return true;
                }
            }

            return false;
        }

        // Loads the existing wind variant for a source material (idempotent re-run) or creates one,
        // then (re)copies the source's base map / colour / cutoff / alpha-clip onto it.
        private static Material GetOrCreateWindVariant(Material source, Shader windShader, ref int createdCount)
        {
            string variantPath = $"{WindMaterialDir}/{Sanitize(source.name)}{WindMaterialSuffix}.mat";

            var variant = AssetDatabase.LoadAssetAtPath<Material>(variantPath);
            if (variant == null)
            {
                variant = new Material(windShader) { name = Path.GetFileNameWithoutExtension(variantPath) };
                AssetDatabase.CreateAsset(variant, variantPath);
                createdCount++;
            }
            else if (variant.shader != windShader)
            {
                variant.shader = windShader;
            }

            CopyLook(source, variant);
            EditorUtility.SetDirty(variant);
            return variant;
        }

        // Preserves the source's visible surface: base map (+ tiling/offset), base colour, cutoff, and
        // whether it alpha-clips. Reads URP/Lit ids first, falling back to legacy _MainTex / _Color so
        // both the FBX-embedded URP materials and any legacy stand-in survive the swap.
        private static void CopyLook(Material source, Material variant)
        {
            Texture baseMap = ReadTexture(source, BaseMapId) ?? ReadTexture(source, MainTexId);
            if (baseMap != null)
            {
                variant.SetTexture(BaseMapId, baseMap);
                variant.SetTextureScale(BaseMapId, ReadScale(source));
                variant.SetTextureOffset(BaseMapId, ReadOffset(source));
            }

            variant.SetColor(BaseColorId, ReadColor(source));

            if (source.HasProperty(CutoffId))
            {
                variant.SetFloat(CutoffId, source.GetFloat(CutoffId));
            }

            bool clips =
                (source.HasProperty(AlphaClipId) && source.GetFloat(AlphaClipId) > 0.5f) ||
                source.IsKeywordEnabled(AlphaTestKeyword);

            variant.SetFloat(AlphaClipId, clips ? 1f : 0f);
            if (clips)
            {
                variant.EnableKeyword(WindAlphaClipKeyword);
            }
            else
            {
                variant.DisableKeyword(WindAlphaClipKeyword);
            }
        }

        private static Texture ReadTexture(Material material, int id) =>
            material.HasProperty(id) ? material.GetTexture(id) : null;

        private static Color ReadColor(Material source)
        {
            if (source.HasProperty(BaseColorId))
            {
                return source.GetColor(BaseColorId);
            }

            return source.HasProperty(ColorId) ? source.GetColor(ColorId) : Color.white;
        }

        private static Vector2 ReadScale(Material source)
        {
            if (source.HasProperty(BaseMapId))
            {
                return source.GetTextureScale(BaseMapId);
            }

            return source.HasProperty(MainTexId) ? source.GetTextureScale(MainTexId) : Vector2.one;
        }

        private static Vector2 ReadOffset(Material source)
        {
            if (source.HasProperty(BaseMapId))
            {
                return source.GetTextureOffset(BaseMapId);
            }

            return source.HasProperty(MainTexId) ? source.GetTextureOffset(MainTexId) : Vector2.zero;
        }

        private static string Sanitize(string name)
        {
            foreach (char invalid in Path.GetInvalidFileNameChars())
            {
                name = name.Replace(invalid, '_');
            }

            return name;
        }

        private static void MarkActiveSceneDirty()
        {
            Scene scene = SceneManager.GetActiveScene();
            if (scene.IsValid())
            {
                EditorSceneManager.MarkSceneDirty(scene);
            }
        }
    }
}
