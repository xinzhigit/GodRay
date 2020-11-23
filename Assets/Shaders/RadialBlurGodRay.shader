Shader "Custom/RadialBlurGodRay" {
    Properties {
        _MainTex("Texture", 2D) = "white" {}
        _BlurTex("Blur", 2D) = "white" {}
    }
    SubShader {
        // Pass 0 提取高光部分
        Pass {
            ZTest Off
            Cull Off
            ZWrite Off
            Fog { Mode Off }

            CGPROGRAM
            #pragma vertex vertThreshold
            #pragma fragment fragThreshold

            #include "RadialBlurGodRay.cginc"
            ENDCG
        }

        // Pass 1 径向模糊
        Pass {
            ZTest Off
            Cull Off
            ZWrite Off
            Fog { Mode Off }

            CGPROGRAM
            #pragma vertex vertBlur
            #pragma fragment fragBlur

            #include "RadialBlurGodRay.cginc"
            ENDCG
        }

        // Pass 1 径向模糊
        Pass {
            ZTest Off
            Cull Off
            ZWrite Off
            Fog { Mode Off }

            CGPROGRAM
            #pragma vertex vertMerge
            #pragma fragment fragMerge

            #include "RadialBlurGodRay.cginc"
            ENDCG
        }
    }
}
