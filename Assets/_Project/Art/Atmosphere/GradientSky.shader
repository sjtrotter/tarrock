Shader "Tarrock/GradientSky"
{
    // A simple three-band gradient skybox: warm pale-gold horizon fading to a cool grey-blue zenith,
    // with a muted ground band below. Used by the Cliff region's dawn mood pass
    // (docs/design/art-audio.md — "pale dawn gold, wind-scoured green"). Renders correctly under URP.
    Properties
    {
        _ZenithColor ("Zenith Color", Color) = (0.32, 0.40, 0.54, 1)
        _HorizonColor ("Horizon Color", Color) = (0.96, 0.87, 0.66, 1)
        _GroundColor ("Ground Color", Color) = (0.40, 0.38, 0.33, 1)
        _Exponent ("Zenith Falloff", Range(0.2, 4)) = 1.35
        _HorizonHeight ("Horizon Height", Range(-0.2, 0.2)) = 0.0
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
            #include "UnityCG.cginc"

            struct appdata { float4 vertex : POSITION; };
            struct v2f { float4 pos : SV_POSITION; float3 dir : TEXCOORD0; };

            fixed4 _ZenithColor;
            fixed4 _HorizonColor;
            fixed4 _GroundColor;
            float _Exponent;
            float _HorizonHeight;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.dir = v.vertex.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float h = normalize(i.dir).y - _HorizonHeight;
                if (h >= 0.0)
                {
                    float t = pow(saturate(h), _Exponent);
                    return lerp(_HorizonColor, _ZenithColor, t);
                }
                float t2 = saturate(-h * 3.0);
                return lerp(_HorizonColor, _GroundColor, t2);
            }
            ENDCG
        }
    }
    Fallback Off
}
