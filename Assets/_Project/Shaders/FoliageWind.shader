Shader "Tarrock/FoliageWind"
{
    // Vertex-sway foliage shader for the stand-in KayKit hex-diorama plants (trees, bushes, tufts).
    // Canon (art-audio.md §The world-state is the art direction): a BOUND region holds its breath —
    // no wind; an UNBOUND region gains motion — wind returns to the foliage. Wind is therefore ONE
    // global scalar, _TarrockWindStrength, driven per-region by Tarrock.Regions.RegionWind via
    // Shader.SetGlobalFloat, scaling ALL displacement so a single call sweeps the whole region.
    //
    // The sway is authored to work on arbitrary STATIC foliage meshes with NO vertex-colour authoring:
    // motion is masked by OBJECT-SPACE HEIGHT (stiff at the base — KayKit props pivot at their base —
    // and most motion toward the top). Meshes that later ship a vertex-colour sway mask still work:
    // colour.a is folded in as an optional multiplier, and meshes with no colour stream read (1,1,1,1)
    // in Unity, so the multiply is a safe no-op when the stream is absent.
    //
    // Two octaves of motion: a broad sway (low frequency, large) plus a small flutter (high frequency,
    // small). Each instance is phase-offset by its world position so a grove never sways in lockstep.
    //
    // House style mirrored from Tarrock/CharacterFadeDither and Tarrock/DustParticle: minimal URP,
    // simple main-light lambert + SH ambient (NOT the full URP/Lit include, which has rendered
    // unreliably on this box for our runtime-swapped materials), SRP-Batcher-compatible CBUFFER.
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        [Toggle(_ALPHACLIP_ON)] _AlphaClip ("Alpha Clip (foliage cards)", Float) = 0
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5

        // Broad sway — the low-frequency lean of the whole plant (world metres at the masked tip).
        _SwayAmplitude ("Sway Amplitude", Float) = 0.06
        _SwayFrequency ("Sway Frequency", Float) = 1.1
        // Flutter — the small, fast tremor layered on top (leaf shiver).
        _FlutterAmplitude ("Flutter Amplitude", Float) = 0.015
        _FlutterFrequency ("Flutter Frequency", Float) = 5.5
        // Height mask — object-space Y below _HeightMaskStart is held rigid; above it, the mask ramps
        // by pow(height - start, exponent) so the base stays planted and the crown carries the motion.
        _HeightMaskStart ("Height Mask Start (OS)", Float) = 0.05
        _HeightMaskExponent ("Height Mask Exponent", Float) = 1.5

        // -- PAINTERLY SHADING (round 12) ------------------------------------------------------
        // Added for the Cliff's hero dead tree, whose bark is the region's signature and which
        // this shader could not express at any value: the round-11 note in
        // TerrainRegionGenerator.Scatter.cs measured that the fragment below was albedo x
        // (sun x N.L x shadow + SH), one flat multiply over BOTH sides of the form, so a
        // warm-lit / cool-shade split was unauthorable from the material. Four of these five
        // terms are Tarrock/RockPainterly's, named and shaped identically so the two shaders
        // stay one vocabulary; _ShadeFill is new and is the one that does the work (see below).
        //
        // EVERY DEFAULT IS THE IDENTITY. wrap 0 -> saturate(N.L); boost 1; tint white; fill
        // black; steps 0 -> the posterize is bypassed. A material that does not set them renders
        // BIT-IDENTICALLY to the pre-round-12 shader, which is why this change is safe to make on
        // a shader the stand-in foliage also uses (FoliageWindInstaller).
        _ShadeWrap ("Shade - lambert wrap", Range(0, 1)) = 0
        _AmbientBoost ("Shade - ambient multiplier", Range(0, 4)) = 1
        // MULTIPLICATIVE cool on the shaded side. Cannot by itself put a warm albedo's shadow on
        // the other side of neutral — it scales R down and B up but the product keeps the
        // albedo's own hue ordering — so it is the SECOND term here, not the first.
        _ShadowTint ("Shade - tint on the shaded side", Color) = (1,1,1,1)
        // ADDITIVE cool fill on the shaded side, gated by (1 - lit), and the reason the bark can
        // finally read cool in shade: it is added AFTER the albedo multiply, so it is the only
        // term in this file that is not multiplied by a warm brown. Physically it is the sky's
        // own light on a surface the sun has left. Authored dark on purpose — it lands on a
        // silhouette, and its luminance cost is what buys or loses the read.
        _ShadeFill ("Shade - ADDITIVE cool fill on the shaded side", Color) = (0,0,0,1)
        // Value planes. 0 or 1 = OFF (the ramp is passed through untouched).
        _BrushSteps ("Shade - value planes (0 = off)", Range(0, 10)) = 0
        _BrushSoftness ("Shade - value plane softness", Range(0.02, 1)) = 0.35

        // Opt-in dead-wood grain. Identity at zero so ordinary foliage remains unchanged.
        _BarkStrength ("Bark - painted relief strength", Range(0, 1)) = 0
        _BarkScale ("Bark - ridge scale per metre", Float) = 5.5
        _BarkCrackDepth ("Bark - crack depth", Range(0, 1)) = 0.62
        _BarkRidgeLift ("Bark - sunward ridge lift", Range(0, 0.5)) = 0.14
        _BarkSunLift ("Bark - warm sunward lift", Color) = (0,0,0,1)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        // Shared across every pass so the UnityPerMaterial layout and the displacement function are
        // defined once — the SRP Batcher requires an identical per-material CBUFFER in all passes, and
        // the shadow/depth verts MUST use the SAME sway as the forward vert or shadows detach.
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _Cutoff;
            float _SwayAmplitude;
            float _SwayFrequency;
            float _FlutterAmplitude;
            float _FlutterFrequency;
            float _HeightMaskStart;
            float _HeightMaskExponent;
            float _ShadeWrap;
            float _AmbientBoost;
            float4 _ShadowTint;
            float4 _ShadeFill;
            float _BrushSteps;
            float _BrushSoftness;
            float _BarkStrength;
            float _BarkScale;
            float _BarkCrackDepth;
            float _BarkRidgeLift;
            float4 _BarkSunLift;
        CBUFFER_END

        // GLOBAL wind scalar — deliberately OUTSIDE UnityPerMaterial so Shader.SetGlobalFloat reaches
        // it and one write sweeps every foliage material at once. A global inside the per-material
        // CBUFFER would neither receive the global value nor be SRP-Batcher-legal.
        float _TarrockWindStrength;

        // The single sway function. Takes object-space position + optional vertex-colour mask, returns
        // the WORLD-space displaced position. Phase is seeded from the instance's world origin so
        // neighbouring plants desync; the wave itself is driven by _Time in world/animation space.
        float3 ApplyFoliageWind(float3 positionOS, float vertexMask)
        {
            float3 positionWS = TransformObjectToWorld(positionOS);

            // Global strength gates everything: a bound region (strength 0) produces zero displacement,
            // so the shader is a plain static-foliage shader until a region unbinds.
            float strength = _TarrockWindStrength;
            if (strength <= 0.0)
            {
                return positionWS;
            }

            // WORLD-space height mask: rigid at the base, ramping toward the crown. Measured as
            // world height above the object's pivot (KayKit/Quaternius foliage pivots sit at the
            // base), so the mask is scale-independent — a grass tuft scaled x125 and a tree scaled
            // x2 both mask by their real metres of height, not their native mesh units.
            float pivotWorldY = unity_ObjectToWorld._m13;
            float heightAboveBase = max((positionWS.y - pivotWorldY) - _HeightMaskStart, 0.0);
            float mask = pow(heightAboveBase, _HeightMaskExponent) * vertexMask;

            // Per-instance phase from the object's world origin (translation column of the M matrix).
            float3 objectWS = float3(unity_ObjectToWorld._m03, unity_ObjectToWorld._m13, unity_ObjectToWorld._m23);
            float phase = dot(objectWS.xz, float2(0.37, 0.53));

            float t = _Time.y;
            // Octave 1 — broad sway along a prevailing wind axis.
            float2 windAxis = normalize(float2(1.0, 0.35));
            float broad = sin(t * _SwayFrequency + phase);
            // Octave 2 — small high-frequency flutter, further varied down the plant by world height.
            float flutter = sin(t * _FlutterFrequency + phase * 1.7 + positionWS.y * 0.25);

            float2 offset = windAxis * (broad * _SwayAmplitude) + windAxis.yx * (flutter * _FlutterAmplitude);
            offset *= mask * strength;

            positionWS.xz += offset;
            return positionWS;
        }

        // Soft posterize — Tarrock/RockPainterly's TkSoftPosterize with ONE difference, and the
        // difference is deliberate: that one returns 0 for steps = 0 (floor(0)=0 divided by
        // max(steps,1)), so "off" would paint the whole plant black. Here anything under two
        // steps passes the ramp straight through, which is what makes 0 a legal default on a
        // shader other materials already use.
        float TkFoliagePosterize(float x, float steps, float softness)
        {
            if (steps < 2.0)
            {
                return x;
            }
            float soft = clamp(softness, 0.02, 1.0) * 0.5;
            float s = x * steps;
            float level = floor(s);
            float f = s - level;
            float e = smoothstep(0.5 - soft, 0.5 + soft, f);
            return saturate((level + e) / steps);
        }

        // Hand-painted split wood without a UV dependency. Three object-space projections are
        // blended by the real mesh normal, so the grain follows the surface without seams and
        // remains useful on both the upright bole and oblique branches. fwidth widens the inked
        // cracks as they recede instead of letting sub-pixel ridges turn into shimmer.
        float TkBarkProfile(float2 p)
        {
            float warp = sin(p.y * 0.73 + sin(p.y * 0.19) * 1.7) * 0.42;
            float across = abs(sin(p.x * 3.14159265 + warp));
            float crackAA = max(fwidth(across), 0.012);
            float crack = 1.0 - smoothstep(0.035 - crackAA, 0.105 + crackAA, across);

            // Broken cross-cuts prevent regular corduroy. They are deliberately rarer and softer
            // than the long splits: broad enough for the 8-60 px contact-lighting read.
            float crossWave = abs(sin(p.y * 1.17 + sin(p.x * 0.61) * 1.3));
            float crossAA = max(fwidth(crossWave), 0.012);
            float crossCrack = (1.0 - smoothstep(0.025 - crossAA, 0.075 + crossAA, crossWave))
                             * smoothstep(0.42, 0.78, across);
            crack = saturate(max(crack, crossCrack * 0.72));

            float ridge = smoothstep(0.32, 0.94, across) * (1.0 - crack);
            return ridge - crack;
        }
        ENDHLSL

        // -----------------------------------------------------------------------------------------
        // Forward lit — simple main-light lambert + SH ambient (house style, Tarrock/CharacterFadeDither).
        // -----------------------------------------------------------------------------------------
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off // foliage cards read from both sides

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ALPHACLIP_ON
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 positionOS : TEXCOORD2;
                float3 normalOS : TEXCOORD3;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = ApplyFoliageWind(IN.positionOS.xyz, IN.color.a);
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.positionOS = IN.positionOS.xyz;
                OUT.normalOS = IN.normalOS;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                #if defined(_ALPHACLIP_ON)
                    clip(baseTex.a - _Cutoff);
                #endif

                float3 normalWS = normalize(IN.normalWS);
                Light mainLight = GetMainLight();

                // ROUND 12 — the painterly split. At the shipped defaults this is the round-11
                // arithmetic term for term: wrapped = saturate(N.L), stepped = wrapped,
                // shade = 1, fill = 0, so `color` reduces to baseTex.rgb * (sun*N.L*atten + SH).
                //
                // GetMainLight() is called WITHOUT a shadow coordinate, exactly as before, so
                // shadowAttenuation is 1 and this tree still does not self-shadow. That is left
                // alone on purpose: turning main-light shadows on here would change the frame by
                // an amount nothing in this round has modelled.
                float ndotl = dot(normalWS, mainLight.direction);
                float wrapped = saturate((ndotl + _ShadeWrap) / (1.0 + _ShadeWrap));
                float stepped = TkFoliagePosterize(wrapped, _BrushSteps, _BrushSoftness);
                float lit = saturate(stepped * mainLight.shadowAttenuation);

                // Bark relief is value paint, not fake geometry: cracks only remove albedo while
                // ridge lift is gated by the actual sun-facing term. Thus the 12-degree key catches
                // ridges, crevices stay dark, and the restored cool shaded side is never brightened
                // by an even/rim function.
                float3 barkWeights = abs(normalize(IN.normalOS));
                barkWeights /= max(barkWeights.x + barkWeights.y + barkWeights.z, 0.001);
                float3 barkP = IN.positionOS * _BarkScale;
                float barkProfile = TkBarkProfile(barkP.zy) * barkWeights.x
                                  + TkBarkProfile(barkP.xz) * barkWeights.y
                                  + TkBarkProfile(barkP.xy) * barkWeights.z;
                float barkCrack = saturate(-barkProfile);
                float barkRidge = saturate(barkProfile);
                float barkValue = 1.0 - barkCrack * _BarkCrackDepth
                                 + barkRidge * _BarkRidgeLift * lit;
                baseTex.rgb *= lerp(1.0, barkValue, _BarkStrength);

                float3 direct = mainLight.color * lit;
                float3 ambient = SampleSH(normalWS) * _AmbientBoost;
                float3 shade = lerp(_ShadowTint.rgb, float3(1.0, 1.0, 1.0), lit);
                float3 color = baseTex.rgb * (direct + ambient) * shade
                             + _ShadeFill.rgb * (1.0 - lit)
                             + _BarkSunLift.rgb * lit * (1.0 - barkCrack) * _BarkStrength;

                return half4(color, 1.0);
            }
            ENDHLSL
        }

        // -----------------------------------------------------------------------------------------
        // Shadow caster — same sway, so a swaying plant throws a swaying shadow.
        // -----------------------------------------------------------------------------------------
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma vertex shadowVert
            #pragma fragment shadowFrag
            #pragma shader_feature_local _ALPHACLIP_ON
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float4 GetShadowClip(float3 positionWS, float3 normalWS)
            {
                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                    float3 lightDirectionWS = _LightDirection;
                #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                return positionCS;
            }

            Varyings shadowVert(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = ApplyFoliageWind(IN.positionOS.xyz, IN.color.a);
                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionHCS = GetShadowClip(positionWS, normalWS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 shadowFrag(Varyings IN) : SV_Target
            {
                #if defined(_ALPHACLIP_ON)
                    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).a * _BaseColor.a;
                    clip(alpha - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }

        // -----------------------------------------------------------------------------------------
        // Depth only — same sway, so depth prepass / SSAO / soft-particle depth stays aligned.
        // -----------------------------------------------------------------------------------------
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma vertex depthVert
            #pragma fragment depthFrag
            #pragma shader_feature_local _ALPHACLIP_ON

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings depthVert(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = ApplyFoliageWind(IN.positionOS.xyz, IN.color.a);
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 depthFrag(Varyings IN) : SV_Target
            {
                #if defined(_ALPHACLIP_ON)
                    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).a * _BaseColor.a;
                    clip(alpha - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }
    }

    Fallback Off
}
