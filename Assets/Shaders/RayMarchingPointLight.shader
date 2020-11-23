Shader "Custom/RayMarchingPointLight" {
	Properties {
		_TintColor("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5)
		_ExtictionFactor("Extiction Factor", Range(0, 0.1)) = 0.01
		_ScatterFactor("Scatter Factor", Range(0, 1)) = 1
	}

	Category {
		Name "FORWARD_DELTA"
		Tags {
			"LightMode" = "ForwardAdd"
			"RenderType" = "Opaque"
			"Queue" = "AlphaTest"
		}
		Blend SrcAlpha One
		Cull Off
		Lighting Off
		ZWrite Off	// 不写深度，永远通过，自己做检测
		ZTest Always

		Fog {Color(0,0,0,0)}

		Subshader {
			Pass {
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"
				#include "UnityDeferredLibrary.cginc"

				// RayMarching步进次数
				#define RAYMARCHING_STEP_COUNT 64

				#pragma shader_feature SHADOW_CUBE
				#pragma shader_feature POINT

				fixed4 _TintColor;
				sampler2D _DitherMap;
				float4x4 _lightMatrix;
				float4x4 _CustomMVP;
				float4 _VolumLightPos;
				float4 _MieScatteringFactor;
				float _ExtictionFactor;
				float _ScatterFactor;

				struct v2f {
					float4 pos : POSITION;
					float3 worldNormal : TEXCOORD0;
					float3 worldPos : TEXCOORD1;
					float4 screenUV : TEXCOORD2;
				};

				// 光的散射
				float MieScatteringFunc(float3 lightDir, float3 rayDir) {
					// MieScattering公式
					// (1 - g^2) / (4 * pi * (1 + g^2 - 2 * g * cosθ)^1.5)
					// _MieScatteringFactor.x = (1 - g^2) / 4 * pi
					// _MieScatteringFactor.y = 1 + g^2
					// _MieScatteringFactor.z = 2 * g
					float lightCos = dot(lightDir, -rayDir);
					return _MieScatteringFactor.x / pow(_MieScatteringFactor.y - _MieScatteringFactor.z * lightCos, 1.5);
				}

				// Beer-Lambert法则(光的吸收)
				float ExtingctionFunc(float stepSize, inout float extinction) {
					float density = 1.0;
					float scattering = _ScatterFactor * stepSize * density;
					extinction += _ExtictionFactor * stepSize * density;
					return scattering * exp(-extinction);
				}

				float4 RayMarching(float3 rayOri, float3 rayDir, float rayLength, float2 ditherUV) {
					// dither
					float2 offsetUV = (fmod(floor(ditherUV), 4.0));
					float ditherValue = tex2D(_DitherMap, offsetUV / 4.0).a;

					float delta = rayLength / RAYMARCHING_STEP_COUNT;
					float3 step = rayDir * delta;
					float3 curPos = rayOri + step;

					float totalAtten = 0;
					float extinction = 0;
					for(int n = 0; n < RAYMARCHING_STEP_COUNT; ++n) {
						float3 toLight = curPos - _VolumLightPos.xyz;
						// 光源衰减
						float atten = 2.0;
						float att = dot(toLight, toLight) * _MieScatteringFactor.w;
						atten * tex2D(_LightTextureB0, att.rr).UNITY_ATTEN_CHANNEL;

						// Mie散射
						atten *= MieScatteringFunc(normalize(-toLight), rayDir);

						// 吸收
						atten *= ExtingctionFunc(delta, extinction);

#if defined(SHADOW_CUBE)
						// 阴影
						atten *= UnityDefferedComputeShadow(toLight, 0, float2(0, 0));
#endif
						
						totalAtten += atten;
						curPos += step;
					}

					float4 color = totalAtten;
					return color * _TintColor;
				}

				v2f vert(appdata_base v) {
					v2f o;
					o.pos = mul(_CustomMVP, v.vertex);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.screenUV = ComputeScreenPos(o.pos);

					return o;
				}

				fixed4 frag(v2f i) : COLOR {
					float3 worldPos = i.worldPos;
					float3 worldCameraPos = _WorldSpaceCameraPos.xyz;
					float rayDis = length(worldCameraPos - worldPos);

					float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenUV.xy / i.screenUV.w);
					float linearDepth = LinearEyeDepth(depth);
					rayDis = min(rayDis, linearDepth);

					return RayMarching(worldCameraPos, normalize(worldPos - worldCameraPos), rayDis, i.pos.xy);
				}
				ENDCG
			}
		}
	}
}
