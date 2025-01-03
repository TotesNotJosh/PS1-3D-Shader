// ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
// Author: TotesNotJosh
// Date: 1/2/2025
// Version: 1.0.0
// Shader: PS1 3D/Vertex Lit
// Description: A custom vertex lit shader for Unity emulating PS1-era graphical effects.
// Including affine texture warping, and integer/fixed-point math for fog, dithering and vertex snapping.
// Designed to achieve a retro look reminiscent of early 3D hardware limitations.
// Update: N/A
// ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
Shader "PS1 3D/Vertex Lit" {
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        [HideInInspector]_SpecColor ("Spec Color", Color) = (0,0,0,0)
        _Emission ("Emissive Color", Color) = (0.0,0.0,0.0,0.0)
        [PowerSlider(5.0)]  _Shininess ("Shininess", Range(0.01,1.0)) = 0.7
        _MainTex ("Base (RGB)", 2D) = "white" { }
        _TransparencyThreshold("Transparency Threshold", Range(0, 1)) = 0.5 // cuts anything with an alpha lower than 128
        _VertexResolution("Vertex Snapping Resolution (Multiplied by 32)", Int) = 2 // Size of the world grid that vertexes snap to 96 looks best to me
        //[MaterialToggle]_Affine("Affine Mapping", Range(0, 1)) = 1 // sets how much affine correction there isn't.
        [MaterialToggle] _UseIntFog("Use Integer Fog Math", Float) = 0 // A bool to determine whether you want a hard edge or use the fixed point system. Fixed point is recommended
        _FogSteps("Integer Fog Steps", Int) = 4 // How many steps you want for int fog
        _FogStart("Fog Start Distance", Int) = 0
        _FogEnd("Fog End Distance", Int) = 20 // Where the world is no longer visible
        _FogColor("Fog Color", Color) = (0.5, 0.5, 0.5, 1)
        [MaterialToggle] _UseDithering("Dither", Float) = 1
        _ColourDepth("Colour Depth", Int) = 32
    }
    SubShader { 
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass {
            Tags { "LIGHTMODE"="Vertex" "RenderType"="Opaque" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"
            #pragma multi_compile_fog
            #define USING_FOG (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
            #if defined(SHADER_API_GLES)
                #define LIGHT_LOOP_LIMIT 8
            #else
                #define LIGHT_LOOP_LIMIT unity_VertexLightParams.x
            #endif

            #if defined(SHADER_API_GLES3) && !defined(SHADER_API_DESKTOP) && (defined(SPOT) || defined(POINT))
                #define LIGHT_LOOP_ATTRIBUTE UNITY_UNROLL
            #else
                #define LIGHT_LOOP_ATTRIBUTE
            #endif
            #define ENABLE_SPECULAR 1

            // Compile specialized variants for when positional (point/spot) and spot lights are present
            #pragma multi_compile __ POINT SPOT

            // Compute illumination from one light, given attenuation
            half3 computeLighting (int idx, half3 dirToLight, half3 eyeNormal, half3 viewDir, half4 diffuseColor, half shininess, half atten, inout half3 specColor) {
                half NdotL = max(dot(eyeNormal, dirToLight), 0.0);
                // diffuse
                half3 color = NdotL * diffuseColor.rgb * unity_LightColor[idx].rgb;
                // specular
                if (NdotL > 0.0) {
                    half3 h = normalize(dirToLight + viewDir);
                    half HdotN = max(dot(eyeNormal, h), 0.0);
                    half sp = saturate(pow(HdotN, shininess));
                    specColor += (atten * sp) * unity_LightColor[idx].rgb;
                }
            return color * atten;
            }

            // Compute attenuation & illumination from one light
            half3 computeOneLight(int idx, float3 eyePosition, half3 eyeNormal, half3 viewDir, half4 diffuseColor, half shininess, inout half3 specColor) {
                float3 dirToLight = unity_LightPosition[idx].xyz;
                half att = 1.0;
                #if defined(POINT) || defined(SPOT)
                    dirToLight -= eyePosition * unity_LightPosition[idx].w;
                    float distSqr = dot(dirToLight, dirToLight);
                    att /= (1.0 + unity_LightAtten[idx].z * distSqr);
                    if (unity_LightPosition[idx].w != 0 && distSqr > unity_LightAtten[idx].w) att = 0.0;
                    distSqr = max(distSqr, 0.000001);
                    dirToLight *= rsqrt(distSqr);
                    #if defined(SPOT)
                        half rho = max(dot(dirToLight, unity_SpotDirection[idx].xyz), 0.0);
                        half spotAtt = (rho - unity_LightAtten[idx].x) * unity_LightAtten[idx].y;
                        att *= saturate(spotAtt);
                    #endif
                #endif
                att *= 0.5;
                return min (computeLighting (idx, dirToLight, eyeNormal, viewDir, diffuseColor, shininess, att, specColor), 1.0);
            }

            //Dither Matrix used by PSX
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

            sampler2D _MainTex;
            half4 _Color;
            half4 _SpecColor;
            half4 _Emission;
            half _Shininess;
            int4 unity_VertexLightParams;
            float4 _MainTex_ST;
            float _TransparencyThreshold;
            float _VertexResolution;
            float _Affine;
            float _UseIntFog;
            float _FogSteps;
            int _FogStart;
            int _FogEnd;
            float4 _FogColor;
            float _UseDithering;
            int _ColourDepth;
            #define FIXED_POINT_SCALE 32
            #define FLOAT_TO_FIXED(x) (int((x) * FIXED_POINT_SCALE))
            #define FIXED_TO_FLOAT(x) ((float(x)) / FIXED_POINT_SCALE)

            struct appdata {
                float3 pos : POSITION;
                float3 normal : NORMAL;
                float3 uv0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 uv0 : TEXCOORD0;
                float4 color : COLOR;
                float fogFactor : TEXCOORD1;
                #if ENABLE_SPECULAR
                float3 specColor : TEXCOORD2;
                #endif
            };

            v2f vert (appdata IN) {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // Calculate world position
                float4 worldPosition = mul(UNITY_MATRIX_MV, float4(IN.pos, 1.0));
                // Vertex snapping
                int fixedX = FLOAT_TO_FIXED(worldPosition.x * _VertexResolution);
                int fixedY = FLOAT_TO_FIXED(worldPosition.y * _VertexResolution);
                int fixedZ = FLOAT_TO_FIXED(worldPosition.z * _VertexResolution);
                worldPosition.x = FIXED_TO_FLOAT(floor(fixedX) / _VertexResolution);
                worldPosition.y = FIXED_TO_FLOAT(floor(fixedY) / _VertexResolution);
                worldPosition.z = FIXED_TO_FLOAT(floor(fixedZ) / _VertexResolution);
                // Calculate screen position
                float4 screenPosition = mul(UNITY_MATRIX_P, worldPosition);
                o.pos = screenPosition;
                float2 uv = TRANSFORM_TEX(IN.uv0, _MainTex);
                o.uv0 = float3(uv * screenPosition.w, screenPosition.w);
                // Fog calculation
                if (_UseIntFog > 0.5) { // Integer math
                    int distance = floor(length(worldPosition.xyz) * _FogSteps);
                    int distanceIntoFog = floor(distance - _FogStart * _FogSteps);
                    int fogRange = floor(_FogEnd - _FogStart) * _FogSteps;
                    o.fogFactor = saturate(floor((float(distanceIntoFog) / float(fogRange)) * _FogSteps) / _FogSteps); // Converts the number to a float between 0 and 1 rounds down to hard steps
                } else { // Fixed-point math
                    int distance = floor(length(worldPosition.xyz) * FIXED_POINT_SCALE);
                    int distanceIntoFog = floor(distance - _FogStart * FIXED_POINT_SCALE);
                    int fogRange = floor((_FogEnd - _FogStart) * FIXED_POINT_SCALE);
                    int fogFactorFixed = (distanceIntoFog * FIXED_POINT_SCALE) / fogRange; // Integer division in fixed-point
                    o.fogFactor = saturate(FIXED_TO_FLOAT(fogFactorFixed)); // Convert back to float for final result
                }
                // Lighting calculations
                half4 color = half4(0, 0, 0, 1.1);
                float3 eyePos = worldPosition.xyz;
                half3 eyeNormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, IN.normal).xyz);
                half3 viewDir = -normalize(eyePos);
                half3 lcolor = _Emission.rgb + _Color.rgb * glstate_lightmodel_ambient.rgb;
                half3 specColor = 0.0;
                half shininess = _Shininess * 128.0;
                LIGHT_LOOP_ATTRIBUTE for (int il = 0; il < LIGHT_LOOP_LIMIT; ++il) {
                    lcolor += computeOneLight(il, eyePos, eyeNormal, viewDir, _Color, shininess, specColor);
                }
                color.rgb = lcolor.rgb;
                color.a = _Color.a;
                specColor *= _SpecColor.rgb;
                o.color = saturate(color);
                #if ENABLE_SPECULAR
                    o.specColor = saturate(specColor);
                #endif
                return o;
            }

            fixed4 frag (v2f IN) : SV_Target {
                float2 uv = IN.uv0.xy / IN.uv0.z; // Affine mode
                fixed4 col = tex2D(_MainTex, uv) * _Color;
                clip(col.a - _TransparencyThreshold); // Cuts out transparent parts
                fixed4 tex;
                tex = tex2D (_MainTex, uv);
                //Apply colour depth
                col.rgb = tex * IN.color;
                col.r = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.r) * (_ColourDepth - 1)) / _ColourDepth);
                col.g = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.g) * (_ColourDepth - 1)) / _ColourDepth);
                col.b = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.b) * (_ColourDepth - 1)) / _ColourDepth);
                col.a = fixed4(1,1,1,1).a;
                // Apply PSX hardware dithering
                if (_UseDithering > 0.5) {
                    float2 scaledPos = IN.pos.xy * (0.65);
                    int2 pos = int2(scaledPos);  
                    int dither = DitherMatrix(pos);
                    int ditherScale = FLOAT_TO_FIXED(1.0 / 16.0);
                    col.r = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.r) * (_ColourDepth - 1) + dither * ditherScale) / _ColourDepth);
                    col.g = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.g) * (_ColourDepth - 1) + dither * ditherScale) / _ColourDepth);
                    col.b = FIXED_TO_FLOAT(floor(FLOAT_TO_FIXED(col.b) * (_ColourDepth - 1) + dither * ditherScale) / _ColourDepth);
                }
                // Apply fog
                fixed4 fogCol = lerp(col, _FogColor, IN.fogFactor); // Sets the fog factor and colour
                clip(1.0 - IN.fogFactor + 0.1); //occludes objects in fog
                return fogCol;
            }
            ENDCG
        }
    }
}