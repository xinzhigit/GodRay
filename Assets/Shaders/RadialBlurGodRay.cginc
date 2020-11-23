#ifndef __RADIALBLUR_GODRAY__
#define __RADIALBLUR_GODRAY__

#define RADIAL_SAMPLE_COUNT 6
#include "UnityCG.cginc"

// 用于提取高亮部分
struct v2fThreshold {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

// 用于Blur
struct v2fBlur {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 blurOffset : TEXCOORD1;
};

// 用于最终融合
struct v2fMerge {
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
};


sampler2D _MainTex;
float4 _MainTex_TexelSize;
sampler2D _BlurTex;
float4 _BlurTex_TexelSize;
float4 _ViewportLightPos;
float4 _Offsets;
float4 _ColorThreshold;
float4 _LightColor;
float _LightFactor;
float _PowFactor;
float _LightRadius;

// 提取高亮部分
v2fThreshold vertThreshold(appdata_img v) {
    v2fThreshold o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;

    // dx中纹理左上角为初始坐标，需要反向
#if UNITY_UV_STARTS_AT_TOP
    if(_MainTex_TexelSize.y < 0) {
        o.uv.y = 1 - o.uv.y;
    }
#endif
    return o;
}

fixed4 fragThreshold(v2fThreshold i) : SV_Target {
    fixed4 color = tex2D(_MainTex, i.uv);
    float distFromLight = length(_ViewportLightPos.xy - i.uv);
    float distControl = saturate(_LightRadius - distFromLight);

    // 仅当color大于设置的阈值时才输出
    float4 thresholdColor = saturate(color - _ColorThreshold) * distControl;
    float luminance = Luminance(thresholdColor.rgb);
    luminance = pow(luminance, _PowFactor);
    return fixed4(luminance, luminance, luminance, 1);
}

// 径向模糊 vertex
v2fBlur vertBlur(appdata_img v) {
    v2fBlur o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;

    // 径向模糊采样偏移值*沿着光的方向的权重
    o.blurOffset = _Offsets * (_ViewportLightPos.xy - o.uv);

    return o;
}

// 径向模糊 fragment
fixed4 fragBlur(v2fBlur i) : SV_Target {
    half4 color = half4(0, 0, 0, 0);
    for(int n = 0; n < RADIAL_SAMPLE_COUNT; ++n) {
        color += tex2D(_MainTex, i.uv);
        i.uv += i.blurOffset;
    }

    return color / RADIAL_SAMPLE_COUNT;
}

// 融合 vertex
v2fMerge vertMerge(appdata_img v) {
    v2fMerge o;

    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.uv1 = o.uv;
#if UNITY_UV_STARTS_AT_TOP
    if(_MainTex_TexelSize.y < 0) {
        o.uv.y = 1 - o.uv.y;
    }
#endif
    return o;
}

fixed4 fragMerge(v2fMerge i) : SV_Target {
    fixed4 ori = tex2D(_MainTex, i.uv1);
    fixed4 blur = tex2D(_BlurTex, i.uv);

    // 输出 = 原始图像叠加体积光
    return ori + _LightFactor * blur * _LightColor;
}

#endif // __RADIALBLUR_GODRAY__
