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
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = ApplyFoliageWind(IN.positionOS.xyz, IN.color.a);
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
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
                float ndotl = saturate(dot(normalWS, mainLight.direction));
                float3 lighting = mainLight.color * (ndotl * mainLight.shadowAttenuation) + SampleSH(normalWS);

                return half4(baseTex.rgb * lighting, 1.0);
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
