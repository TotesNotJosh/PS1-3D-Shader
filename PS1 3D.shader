// ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
// Author: TotesNotJosh
// Date: 12/30/2024
// Version: 1.0
// Shader: PS1 3D/Unlit
// Description: A custom unlit shader for Unity emulating PS1-era graphical effects.
// Including affine texture warping, and integer/fixed-point math for fog and vertex snapping.
// Designed to achieve a retro look reminiscent of early 3D hardware limitations.
// ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
Shader "PS1 3D/Unlit"
{
    Properties
    {
        _MainTex("Base", 2D) = "white" {}
        [HideInInspector] _Color("Color", Color) = (0.25, 0.25, 0.25, 1) //Darkened for better ambience with the unlit style
        _TransparencyThreshold("Transparency Threshold", Range(0, 1)) = 0.5 //cuts anything with an alpha lower than 128
        _VertexResolution("Vertex Snapping Resolution", Float) = 96 //Size of the world grid that vertexes snap to 96 looks best to me
        _Affine("Affine Mapping", Range(0, 1)) = 1 //sets how much affine correction there isn't. 
        [MaterialToggle] _UseIntFog("Use Integer Fog Math", Float) = 0 //A bool to determine whether you want a hard edge or use the fixed point system. Fixed point is recommended
        _FixedPointScale("Scale For Fixed Point Math", Float) = 4 //How many steps you want for fog
        _FogStart("Fog Start Distance", Int) = 0 //Works additively in fixed point, doesn't do anything in integer. 
        _FogEnd("Fog End Distance", Int) = 20 //Where the world is no longer visible
        _FogColor("Fog Color", Color) = (0.5, 0.5, 0.5, 1)
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog //disable unity's fog settings
            #undef UNITY_FOG

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 texcoord : TEXCOORD;
                float fogFactor : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _TransparencyThreshold;
            float _VertexResolution;
            float _Affine;
            float _UseIntFog;
            float _FixedPointScale;
            int _FogStart;
            int _FogEnd;
            float4 _FogColor;

            //Rounds down and converts to int
            int floorInt(float x)
            {
                return (int)floor(x);
            }

            v2f vert(appdata_base v)
            {
                v2f o;
                // Snap to grid using integer math to better emulate PSX jitter
                float4 wp = mul(UNITY_MATRIX_MV, v.vertex);
                wp.xyz = float3(floorInt(wp.x * _VertexResolution) / _VertexResolution,
                                floorInt(wp.y * _VertexResolution) / _VertexResolution,
                                floorInt(wp.z * _VertexResolution) / _VertexResolution);
                float4 sp = mul(UNITY_MATRIX_P, wp);
                o.position = sp;
                float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.texcoord = float3(uv * sp.w, sp.w);

                // Fog calculation. integer, or fixed point
                if (_UseIntFog > 0.5){ //integer math
                    int distance = int(length(wp.xyz));
                    int distanceIntoFog = (distance - _FogStart);
                    int fogRange = (_FogEnd - _FogStart);
                    o.fogFactor = saturate(int(distanceIntoFog) / int(fogRange));
                } else{ //fixed point math
                    int distance = int(length(wp.xyz) * _FixedPointScale); //This whole section converts float values to fixed-point values.
                    int distanceIntoFog = int(distance - _FogStart * _FixedPointScale);
                    int fogRange = int(_FogEnd - _FogStart) * _FixedPointScale;
                    o.fogFactor = saturate(floor((float(distanceIntoFog) / float(fogRange)) * _FixedPointScale) / _FixedPointScale); //Converts the number to a float between 0 and 1 rounds down to hard steps
                }
                return o;
            }
            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv;
                // Affine range: 0 = perspective correct, 1 = full affine, 0.75 looks best in my opinion. More triangles makes the affine effect less noticeable
                uv = i.texcoord.xy / i.texcoord.z;
                fixed4 col = tex2D(_MainTex, uv) * _Color * 2; // Base colour
                clip(col.a - _TransparencyThreshold); //Cuts out transparent parts
                fixed4 fogCol = lerp(col, _FogColor, i.fogFactor); // Sets the fog factor and colour
                return fogCol;
            }
            ENDCG
        }
    }
}
