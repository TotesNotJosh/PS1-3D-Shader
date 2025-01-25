// ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
// Author: TotesNotJosh
// Date: 1/25/2025
// Version: 1.2.0
// Shader: PS1 3D/Unlit
// Description: A custom unlit shader for Unity emulating PS1-era graphical effects.
// Including affine texture warping, and integer/fixed-point math for fog, dithering and vertex snapping.
// Designed to achieve a retro look reminiscent of early 3D hardware limitations.
// Update: Huge overhaul to dithering, looked at actual PSX dithered images and reverse engineered them testing color values and positions,
//         switched the ditering to work on the texture not screen as well.
// ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
Shader "PS1 3D/Unlit"
{
    Properties {
        _Color("Main Color", Color) = (1.0, 1.0, 1.0, 1) //Darken for better ambience with the unlit style
        _MainTex("Base (RGB)", 2D) = "white" { }
        [Header(Transparency)][Space]
        [MaterialToggle]_BlackClipping("Clip Black Pixels", Float) = 1 //Clips out black
        _TransparencyThreshold("Alpha Threshold", Range(0, 1)) = 0.5 //cuts anything with an alpha lower than 128
        [Header(Effects)][Space]
        [IntRange]_VertexResolution("Vertex Snapping Resolution (Multiplied by 32)", Range(0,8)) = 4 //Size of the world grid that vertexes snap to 96 looks best to me
        [MaterialToggle]_Affine("Affine Mapping", Range(0, 1)) = 1 // Toggles texture warping based on perspective
        [MaterialToggle] _UseIntFog("Use Integer Fog Math", Float) = 0 //A bool to determine whether you want a hard edge or use the fixed point system. Fixed point is recommended
        _FogSteps("Integer Fog Steps", Int) = 4 //How many steps you want for int fog
        _FogStart("Fog Start Distance", Int) = 5
        _FogEnd("Fog End Distance", Int) = 20 //Where the world is no longer visible
        _FogColor("Fog Color", Color) = (0.25, 0.25, 0.25, 1)
        [MaterialToggle] _UseDithering("Dither", Float) = 1
        _ColorDepth("Color Depth", Int) = 32
    }
    SubShader {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100
        Pass {
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog //Disable unity's fog settings
            #undef UNITY_FOG
            struct v2f {
                float4 position : SV_POSITION;
                float3 texcoord : TEXCOORD;
                float fogFactor : TEXCOORD1;
            };
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;
            float4 _Color;
            float _BlackClipping;
            float _TransparencyThreshold;
            float _VertexResolution;
            float _Affine;
            float _UseIntFog;
            float _FogSteps;
            int _FogStart;
            int _FogEnd;
            float4 _FogColor;
            float _UseDithering;
            int _ColorDepth;
            #define FIXED_POINT_SCALE 32
            #define FLOAT_TO_FIXED(x) (int((x) * FIXED_POINT_SCALE))
            #define FIXED_TO_FLOAT(x) ((float(x)) / FIXED_POINT_SCALE)

            //Dither Matrix used by the PSXACT emulator
            int DitherMatrix(int2 uv) {
                const int ditherValue = 8;
                const int ditherMatrix[16] = {
                    -ditherValue, ditherValue, -ditherValue, ditherValue,
                     ditherValue, -ditherValue, ditherValue, -ditherValue,
                    -ditherValue, ditherValue, -ditherValue, ditherValue,
                     ditherValue, -ditherValue, ditherValue, -ditherValue
                };
                return ditherMatrix[(uv.x % 4) + (uv.y % 4) * 4];
            }
            int floorInt(float x) {
                return (int)floor(x);
            }
            v2f vert(appdata_base v) {
                v2f o;
                // Calculate world position
                float4 worldPosition = mul(UNITY_MATRIX_MV, v.vertex);
                // Vertex snapping
                if (_VertexResolution > 0) {
                    int fixedX = FLOAT_TO_FIXED(worldPosition.x * _VertexResolution);
                    int fixedY = FLOAT_TO_FIXED(worldPosition.y * _VertexResolution);
                    int fixedZ = FLOAT_TO_FIXED(worldPosition.z * _VertexResolution);
                    worldPosition.x = FIXED_TO_FLOAT(floor(fixedX) / _VertexResolution);
                    worldPosition.y = FIXED_TO_FLOAT(floor(fixedY) / _VertexResolution);
                    worldPosition.z = FIXED_TO_FLOAT(floor(fixedZ) / _VertexResolution);
                }
                // Calculate screen position
                float4 screenPosition = mul(UNITY_MATRIX_P, worldPosition);
                o.position = screenPosition;
                float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                if (_Affine > 0.5) {
                    // For affine mapping, multiply UV by W
                    o.texcoord = float3(uv * screenPosition.w, screenPosition.w);
                } else {
                    // For perspective correct mapping, store original UV and W
                    o.texcoord = float3(uv, screenPosition.w);
                }
                // Fog calculation
                if (_UseIntFog > 0.5){ // Integer math
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
            fixed4 frag(v2f i) : SV_Target {
                float2 uv;
                if (_Affine > 0.5){
                    uv = i.texcoord.xy / i.texcoord.z; // Affine mode
                } else {
                    uv = i.texcoord.xy;
                }
                fixed4 col = tex2D(_MainTex, uv);
                //Clip out black pixels
                if (_BlackClipping > 0.5) {
                    if (col.r * 255 <= 15 && col.g * 255 <= 15 && col.b * 255 <= 15) {
                        clip(-1);
                    }
                    col = col * _Color;
                }
                clip(col.a - _TransparencyThreshold); // Cuts out transparent pixels
                if (_UseDithering > 0.5) {
                    int2 texelPos = int2(floor(uv * _MainTex_TexelSize.zw)); // Use .zw for texture size
                    int dither = DitherMatrix(texelPos);
                    col.rgb = saturate(floor((col.rgb * 255) + dither) / 255);
                }
                // Apply color depth
                col.rgb = saturate((floor(col.rgb * (_ColorDepth - 1)) / (_ColorDepth - 1)));
                col.a = fixed4(1,1,1,1).a;
                // Apply fog
                fixed4 fogCol = lerp(col, _FogColor, i.fogFactor); //Sets the fog factor and color
                clip(1.0 - i.fogFactor + 0.1); //occludes objects in fog
                return fogCol;
            }
            ENDCG
        }
    }
    CustomEditor "PS1ShaderGUI"
}
