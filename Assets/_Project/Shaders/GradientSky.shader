Shader "Tarrock/GradientSky"
{
    // The Cliff's frozen dawn, as a skybox. All the gradient maths lives in SkyGradient.hlsl,
    // which Tarrock/CloudSea includes too — see that file's header for why they must share it.
    //
    // What this shader is FOR (2026-07-31 look pass): at the gameplay camera's pitch the player
    // only ever sees the first ~25° of sky, so the sky has to do all of its work down there —
    // a pale gold band lying on the cloud sea, a cooler cream above it, a blue zenith reserved
    // for the vantages that look up, soft painted terraces throughout, and a dawn blaze sitting
    // on the horizon down the valley the Fool is walking toward. Reference board: fable-03,
    // fable-04, animation-04.
    //
    // Note what is NOT here: a ground colour. Below the horizon the Cliff has no ground — it has
    // the cloud sea (world.md §The Cliff), and the lower hemisphere settles on the same haze the
    // fog and the deck settle on.
    //
    // ROUND 2 (2026-07-31, against Assets/Screenshots/gauntlet/round1/v3-v4): the vault held not
    // one cloud shape and the horizon had no value anchor, so the brightest zone in the frame sat
    // straight on the second-brightest and nothing said the world ENDED. Both fixes are in
    // SkyGradient.hlsl, so the cloud deck inherits them and the join stays seamless: a lumpy far
    // cloud bank standing on the horizon (its cool body is the anchor) and designed cumulus masses
    // in the vault, placed here relative to the sun by TerrainRegionGenerator.
    //
    // ROUND 3 (against round2/v3-v4): the bank landed — v3's crest reads as a line of distant
    // island silhouettes — but the vault masses came out as "one blurred lozenge", and the sky
    // still had no value darker than mid anywhere in the top 60% of frame. The rewrite is again
    // entirely in SkyGradient.hlsl (see its header): an isotropic six-lobe alphabet, three washes
    // with a terminator per lobe, a fifth mass, and a genuinely dark belly on the big ones. This
    // file only carries the property list.
    Properties
    {
        _HorizonColor ("Horizon - pale dawn gold", Color) = (0.92, 0.82, 0.62, 1)
        _MidColor ("Low sky - cooler cream", Color) = (0.58, 0.62, 0.69, 1)
        _ZenithColor ("Zenith - cool blue", Color) = (0.20, 0.32, 0.54, 1)
        _HazeColor ("Below horizon - the cloud sea at infinity", Color) = (0.90, 0.85, 0.74, 1)
        _SunGlowColor ("Dawn blaze tint", Color) = (1.00, 0.84, 0.58, 1)
        _SunDirection ("Direction TO the sun (xyz)", Vector) = (-0.94, 0.276, -0.2, 0)

        _MidHeight ("Mid band height (sin elevation)", Range(0.05, 0.95)) = 0.44
        _HazeDepth ("Below-horizon fade depth (sin elevation)", Range(0.01, 0.6)) = 0.09
        _GlowFalloff ("Blaze - falloff from the horizon", Range(1, 30)) = 7
        _GlowBroad ("Blaze - broad lobe", Range(0, 2)) = 0.22
        _GlowBroadPower ("Blaze - broad tightness", Range(1, 16)) = 8
        _GlowCore ("Blaze - core", Range(0, 4)) = 0.55
        _GlowCorePower ("Blaze - core tightness", Range(8, 400)) = 120

        _BandCount ("Painted bands", Range(2, 24)) = 7
        _BandStrength ("Band strength", Range(0, 1)) = 0.30
        _BandSoftness ("Band softness", Range(0.02, 0.5)) = 0.22

        _HorizonHeight ("Horizon height", Range(-0.2, 0.2)) = 0.0
        _Dither ("Dither (kills 8-bit ramp banding)", Range(0, 0.02)) = 0.0035

        // The far cloud bank — the cloud sea's skyline, and the frame's value anchor.
        _BankCrestColor ("Bank - lit crest", Color) = (1.02, 0.97, 0.87, 1)
        _BankShadeColor ("Bank - shaded body (the value anchor)", Color) = (0.50, 0.53, 0.65, 1)
        _BankHeight ("Bank - mean crest height (sin elevation)", Range(-0.05, 0.15)) = 0.020
        _BankRelief ("Bank - crest rise and fall", Range(0, 0.12)) = 0.045
        _BankLumpScale ("Bank - cloud heads per compass turn", Range(1, 24)) = 5
        _BankRimWidth ("Bank - lit rim depth", Range(0.001, 0.04)) = 0.0060
        _BankBodyDepth ("Bank - shaded body depth", Range(0.002, 0.1)) = 0.024
        _BankDissolve ("Bank - dissolve into haze", Range(0.002, 0.1)) = 0.034
        _BankFloor ("Bank - base (sin elevation)", Range(-0.1, 0.05)) = -0.012
        _BankFade ("Bank - fade below the base", Range(0.005, 0.1)) = 0.042
        _BankGapStart ("Bank - gap window start", Range(0, 1)) = 0.36
        _BankGapEnd ("Bank - gap window end", Range(0, 1)) = 0.46

        // Five designed masses in the vault: (bearing°, elevation°, half width°, opacity).
        _VaultCloud0 ("Vault cloud 0 (the hero)", Vector) = (288, 12.0, 20.0, 0.94)
        _VaultCloud1 ("Vault cloud 1", Vector) = (358, 8.5, 8.0, 0.72)
        _VaultCloud2 ("Vault cloud 2", Vector) = (234, 25.0, 24.0, 0.26)
        _VaultCloud3 ("Vault cloud 3", Vector) = (77, 10.5, 15.0, 0.82)
        _VaultCloud4 ("Vault cloud 4", Vector) = (40, 7.0, 11.0, 0.66)
        _VaultCloudLit ("Vault cloud - sunlit crowns", Color) = (1.02, 0.97, 0.87, 1)
        _VaultCloudShade ("Vault cloud - cool body", Color) = (0.52, 0.57, 0.71, 1)
        _VaultCloudShadow ("Vault cloud - belly (the dark anchor)", Color) = (0.19, 0.23, 0.35, 1)
        _VaultCloudBase ("Vault cloud - flat base (half widths)", Range(0.05, 0.6)) = 0.22
        _VaultCloudSoftness ("Vault cloud - edge softness", Range(0.005, 0.3)) = 0.030
        _VaultCloudLump ("Vault cloud - cauliflower", Range(0, 0.4)) = 0.090
    }

    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "SkyGradient.hlsl"

            struct appdata { float4 vertex : POSITION; };
            struct v2f { float4 pos : SV_POSITION; float3 dir : TEXCOORD0; };

            // float4, not fixed4: the blaze is deliberately allowed over 1 so the post volume's
            // bloom can catch it, and fixed clamps.
            float4 _HorizonColor;
            float4 _MidColor;
            float4 _ZenithColor;
            float4 _HazeColor;
            float4 _SunGlowColor;
            float4 _SunDirection;
            float _MidHeight;
            float _HazeDepth;
            float _GlowFalloff;
            float _GlowBroad;
            float _GlowBroadPower;
            float _GlowCore;
            float _GlowCorePower;
            float _BandCount;
            float _BandStrength;
            float _BandSoftness;
            float _HorizonHeight;
            float _Dither;
            float4 _BankCrestColor;
            float4 _BankShadeColor;
            float _BankHeight;
            float _BankRelief;
            float _BankLumpScale;
            float _BankRimWidth;
            float _BankBodyDepth;
            float _BankDissolve;
            float _BankFloor;
            float _BankFade;
            float _BankGapStart;
            float _BankGapEnd;
            float4 _VaultCloud0;
            float4 _VaultCloud1;
            float4 _VaultCloud2;
            float4 _VaultCloud3;
            float4 _VaultCloud4;
            float4 _VaultCloudLit;
            float4 _VaultCloudShade;
            float4 _VaultCloudShadow;
            float _VaultCloudBase;
            float _VaultCloudSoftness;
            float _VaultCloudLump;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.dir = v.vertex.xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                TarrockSkyDesc sky;
                TARROCK_FILL_SKY_DESC(sky)

                float3 dir = normalize(i.dir);
                float3 color = TarrockSkyColor(dir, sky);

                // A wide smooth ramp across a whole screen is exactly where an 8-bit target shows
                // contour rings. Dither is world-direction keyed, so the pattern is nailed to the
                // sky and does not crawl when the camera turns.
                color += (TarrockHash21(dir.xz * 512.0 + dir.y * 97.0) - 0.5) * _Dither;

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
    Fallback Off
}
