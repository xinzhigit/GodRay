#ifndef __VOLUMELIGHT_RAYMARCHING_POSTEFFECT__
#define __VOLUMELIGHT_RAYMARCHING_POSTEFFECT__

#include "UnityCG.cginc"

// blur
struct v2fBlur {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float4 uv01 : TEXCOORD1;
	float4 uv23 : TEXCOORD2;
	float4 uv45 : texcoord3;
};

struct v2fAdd {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
};

sampler2D _MainTex;
float4 _MainTex_TexelSize;
sampler2D _VolumeLightTex;
float4 _VolumeLightTex_TexelSize;
float4 _Offsets;
float4 _ColorThreshold;

// 高斯模糊
v2fBlur vertBlur(appdata_img v) {
	v2fBlur o;
	_Offsets *= _MainTex_TexelSize.xyxy;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord;

	
	o.uv01 = v.texcoord.xyxy + _Offsets.xyxy * float4(1, 1, -1, -1);
	o.uv23 = v.texcoord.xyxy + _Offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
	o.uv45 = v.texcoord.xyxy + _Offsets.xyxy * float4(1, 1, -1, -1) * 3.0;

	return o;
}

fixed4 fragBlur(v2fBlur i) : SV_Target {
	fixed4 color = fixed4(0,0,0,0);
	color += 0.40 * tex2D(_MainTex, i.uv);
	color += 0.15 * tex2D(_MainTex, i.uv01.xy);
	color += 0.15 * tex2D(_MainTex, i.uv01.zw);
	color += 0.10 * tex2D(_MainTex, i.uv23.xy);
	color += 0.10 * tex2D(_MainTex, i.uv23.zw);
	color += 0.05 * tex2D(_MainTex, i.uv45.xy);
	color += 0.05 * tex2D(_MainTex, i.uv45.zw);
	return color;
}

v2fAdd vertAdd(appdata_img v) {
	v2fAdd o;
	//mvp矩阵变换
	o.pos = UnityObjectToClipPos(v.vertex);
	//uv坐标传递
	o.uv.xy = v.texcoord.xy;
	o.uv1.xy = o.uv.xy;
#if UNITY_UV_STARTS_AT_TOP
	if (_MainTex_TexelSize.y < 0)
		o.uv.y = 1 - o.uv.y;
#endif	
	return o;
}

fixed4 fragAdd(v2fAdd i) : SV_Target {
	fixed4 ori = tex2D(_MainTex, i.uv1);
	fixed4 light = tex2D(_VolumeLightTex, i.uv);

	return ori + light;
}

#endif // __VOLUMELIGHT_RAYMARCHING_POSTEFFECT__
