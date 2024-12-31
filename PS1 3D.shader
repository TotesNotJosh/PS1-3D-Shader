// ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
// Author: TotesNotJosh
// Date: 12/31/2024
// Version: 1.1.0
// Shader: PS1 3D/Unlit
// Description: A custom unlit shader for Unity emulating PS1-era graphical effects.
// Including affine texture warping, and integer/fixed-point math for fog and vertex snapping.
// Designed to achieve a retro look reminiscent of early 3D hardware limitations.
// Update: Added in shader dithering. Affine is permanently on until I figure out how to fix it non-affine. Converted almost all math to int based.
// ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
Shader "PS1 3D/Unlit"
{
    Properties
    {
        _MainTex("Base", 2D) = "white" {}
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1) //Darken for better ambience with the unlit style
        _TransparencyThreshold("Transparency Threshold", Range(0, 1)) = 0.5 //cuts anything with an alpha lower than 128
        _VertexResolution("Vertex Snapping Resolution (Multiplied by 32)", Int) = 2 //Size of the world grid that vertexes snap to 96 looks best to me
        //[MaterialToggle]_Affine("Affine Mapping", Range(0, 1)) = 1 //sets how much affine correction there isn't. 
        [MaterialToggle] _UseIntFog("Use Integer Fog Math", Float) = 0 //A bool to determine whether you want a hard edge or use the fixed point system. Fixed point is recommended
        _FogSteps("Integer Fog Steps", Int) = 4 //How many steps you want for int fog
        _FogStart("Fog Start Distance", Int) = 0 //Works additively in fixed point, doesn't do anything in integer. 
        _FogEnd("Fog End Distance", Int) = 20 //Where the world is no longer visible
        _FogColor("Fog Color", Color) = (0.5, 0.5, 0.5, 1)
        [MaterialToggle] _UseDithering("Dither", Float) = 1
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
            #pragma multi_compile_fog //Disable unity's fog settings
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
            float _FogSteps;
            int _FogStart;
            int _FogEnd;
            float4 _FogColor;
            float _UseDithering;
            #define FIXED_POINT_SCALE 32
            #define FLOAT_TO_FIXED(x) (int((x) * FIXED_POINT_SCALE))
            #define FIXED_TO_FLOAT(x) ((float(x)) / FIXED_POINT_SCALE)
            #define COLOUR_DEPTH 32

            //Dither Matrix used by the PSXACT emulator
            int DitherMatrix(int2 uv)
            {
                const int ditherMatrix[16] = {
                    -4, 0, -3, 1,
                     2, -2, 3, -1,
                    -3, 1, -4, 0,
                     3, -1, 2, -2
                };
                return ditherMatrix[(uv.x % 4) + (uv.y % 4) * 4];
            }
            int floorInt(float x)
            {
                return (int)floor(x);
            }
            v2f vert(appdata_base v)
            {
                v2f o;
                //Snap to grid using integer math to better emulate PSX jitter
                float4 worldPosition = mul(UNITY_MATRIX_MV, v.vertex);
                int fixedX = FLOAT_TO_FIXED(worldPosition.x * _VertexResolution);
                int fixedY = FLOAT_TO_FIXED(worldPosition.y * _VertexResolution);
                int fixedZ = FLOAT_TO_FIXED(worldPosition.z * _VertexResolution);

                worldPosition.x = FIXED_TO_FLOAT(floor(fixedX) / _VertexResolution);
                worldPosition.y = FIXED_TO_FLOAT(floor(fixedY) / _VertexResolution);
                worldPosition.z = FIXED_TO_FLOAT(floor(fixedZ) / _VertexResolution);
                float4 screenPosition = mul(UNITY_MATRIX_P, worldPosition);
                o.position = screenPosition;

                float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.texcoord = float3(uv * screenPosition.w, screenPosition.w);

                // Fog calculation. integer, or fixed point
                if (_UseIntFog > 0.5){ //integer math
                    int distance = floor(length(worldPosition.xyz) * _FogSteps);
                    int distanceIntoFog = floor(distance - _FogStart * _FogSteps);
                    int fogRange = floor(_FogEnd - _FogStart) * _FogSteps;
                    o.fogFactor = saturate(floor((float(distanceIntoFog) / float(fogRange)) * _FogSteps) / _FogSteps); //Converts the number to a float between 0 and 1 rounds down to hard steps
                } else { // Fixed-point math
                    int distance = floor(length(worldPosition.xyz) * FIXED_POINT_SCALE);
                    int distanceIntoFog = floor(distance - _FogStart * FIXED_POINT_SCALE);
                    int fogRange = floor((_FogEnd - _FogStart) * FIXED_POINT_SCALE);
                    int fogFactorFixed = (distanceIntoFog * FIXED_POINT_SCALE) / fogRange; //Integer division in fixed-point
                    o.fogFactor = saturate(FIXED_TO_FLOAT(fogFactorFixed)); //Convert back to float for final result
                }
                return o;
            }
            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv;
                uv = i.texcoord.xy / i.texcoord.z;//Affine mode
                fixed4 col = tex2D(_MainTex, uv) * _Color;//Base colour
                clip(col.a - _TransparencyThreshold); //Cuts out transparent parts
                //Apply PSX hardware dithering
                if (_UseDithering > 0.5){
                    int2 pos = int2(i.position.xy);  
                    int dither = DitherMatrix(pos);
                    int ditherScale = FLOAT_TO_FIXED(1.0 / 16.0);
                    col.r = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.r) * (COLOUR_DEPTH - 1) + dither * ditherScale) / COLOUR_DEPTH);
                    col.g = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.g) * (COLOUR_DEPTH - 1) + dither * ditherScale) / COLOUR_DEPTH);
                    col.b = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.b) * (COLOUR_DEPTH - 1) + dither * ditherScale) / COLOUR_DEPTH);
                }
                fixed4 fogCol = lerp(col, _FogColor, i.fogFactor); //Sets the fog factor and colour
                return fogCol;
            }
            ENDCG
        }
    }
}
