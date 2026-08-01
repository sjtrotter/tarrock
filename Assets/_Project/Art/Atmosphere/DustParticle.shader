Shader "Tarrock/DustParticle"
{
    // Minimal URP-compatible unlit, vertex-coloured, alpha-blended particle shader for the Fool's
    // footfall dust (PlayerDustPuffs). Built explicitly because URP renders the legacy built-in
    // particle shaders unreliably and a code-created "URP/Particles/Unlit" material needs keyword
    // setup the material editor normally does. rgb comes from the particle colour (warm dust tint,
    // faded by colorOverLifetime); alpha is the particle alpha times the soft-dot texture.
    //
    // _SoftDot exists because of a real failure: round1/v8 of the 2026-07-31 gauntlet caught the
    // suspended motes as a plain white SQUARE hanging in the sky. TerrainRegionGenerator.BuildMotes
    // creates its material with no sprite, an unassigned texture property resolves to Unity's
    // built-in white — alpha 1 across the whole billboard — and the particle drew as its own
    // untextured quad. Turning _SoftDot up replaces the sampled alpha with a soft radial falloff
    // computed from the quad's own UV, so a system that just wants a dust mote needs no texture
    // asset at all and CANNOT regress into a square. Default 0 leaves sprite-driven systems
    // (PlayerDustPuffs and its authored DustMaterial) bit-for-bit unchanged.
    Properties
    {
        _MainTex ("Dust Sprite", 2D) = "white" {}
        _SoftDot ("Procedural soft dot (replaces the sprite alpha)", Range(0, 1)) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "PreviewType" = "Plane"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off
        Lighting Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float _SoftDot;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.color = IN.color;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // A quadratic radial falloff on the quad's own UV: 1 at the centre, 0 on the
                // inscribed circle, squared so the edge dies softly instead of forming a disc.
                half2 offset = IN.uv - 0.5;
                half radial = saturate(1.0 - dot(offset, offset) * 4.0);
                radial *= radial;

                half mask = lerp(tex.a, radial, _SoftDot);
                return half4(IN.color.rgb, IN.color.a * mask);
            }
            ENDHLSL
        }
    }

    Fallback Off
}
