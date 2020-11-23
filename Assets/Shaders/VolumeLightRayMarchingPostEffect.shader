Shader "Custom/VolumeLightRayMarchingPostEffect" {
	Properties {
		_MainTex("Main Tex", 2D) = "white" {}
		_VolumeLightTex("Volume", 2D) = "white" {}
	}

	SubShader {
		// pass 0 高斯模糊
		Pass {
			ZTest Off
			Cull Off
			ZWrite Off
			Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vertBlur
			#pragma fragment fragBlur

			#include "VolumeLightRayMarchingPostEffect.cginc"
			ENDCG
		}

		// pass 1 叠加
		Pass {
			ZTest Off
			Cull Off
			ZWrite Off
			Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vertAdd
			#pragma fragment fragAdd

			#include "VolumeLightRayMarchingPostEffect.cginc"
			ENDCG
		}
	}
}
