using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RadialBlurGodRay : PostEffectBase {
    /// <summary>
    /// 高光部分提取阈值
    /// </summary>
    public Color colorThreshold = Color.gray;

    /// <summary>
    /// 体积光颜色
    /// </summary>
    public Color lightColor = Color.white;

    /// <summary>
    /// 光强度
    /// </summary>
    [Range(0.0f, 20.0f)]
    public float lightFactor = 0.5f;

    /// <summary>
    /// 径向模糊uv采样偏移值
    /// </summary>
    [Range(0.0f, 1000.0f)]
    public float samplerScale = 1;

    /// <summary>
    /// blur迭代次数
    /// </summary>
    [Range(1, 3)]
    public int blurIteration = 2;

    /// <summary>
    /// 降低分辨率的倍率
    /// </summary>
    [Range(0, 3)]
    public int downSample = 1;

    /// <summary>
    /// 光源位置
    /// </summary>
    public Transform lightTrans;

    /// <summary>
    /// 体积光的范围
    /// </summary>
    [Range(0.0f, 5.0f)]
    public float lightRadius = 2.0f;

    /// <summary>
    /// 提取高亮结果的倍率，适当降低颜色过亮的情况
    /// </summary>
    [Range(1.0f, 4.0f)]
    public float lightPowFactor = 3.0f;

    private Camera targetCamera = null;
    private int _colorThresholdId = Shader.PropertyToID("_ColorThreshold");
    private int _viewportLightPosId = Shader.PropertyToID("_ViewportLightPos");
    private int _lightRadiusId = Shader.PropertyToID("_LightRadius");
    private int _powFactorId = Shader.PropertyToID("_PowFactor");
    private int _offsetsId = Shader.PropertyToID("_Offsets");
    private int _blurTexId = Shader.PropertyToID("_BlurTex");
    private int _lightColorId = Shader.PropertyToID("_LightColor");
    private int _lightFactorId = Shader.PropertyToID("_LightFactor");

    private void Awake() {
        targetCamera = GetComponent<Camera>();
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if(material) {
            int rtWidth = source.width >> downSample;
            int rtHeight = source.height >> downSample;

            RenderTexture temp1 = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, source.format);

            // 计算光源位置从世界空间转换到视口空间
            Vector3 viewportLightPos = new Vector3(0.5f, 0.5f, 0f);
            if (lightTrans) {
                viewportLightPos = targetCamera.WorldToViewportPoint(lightTrans.position);
            }

            material.SetVector(_colorThresholdId, colorThreshold);
            material.SetVector(_viewportLightPosId, new Vector4(viewportLightPos.x, viewportLightPos.y, viewportLightPos.z, 0));
            material.SetFloat(_lightRadiusId, lightRadius);
            material.SetFloat(_powFactorId, lightPowFactor);

            // 根据阈值提取高亮部分
            Graphics.Blit(source, temp1, material, 0);

            material.SetVector(_viewportLightPosId, new Vector4(viewportLightPos.x, viewportLightPos.y, viewportLightPos.z, 0));
            material.SetFloat(_lightRadiusId, lightRadius);
            // 径向模糊的采样UV偏移值
            float samplerOffset = samplerScale / source.width;
            // 径向模糊，两次一组，迭代
            for (int n = 0; n < blurIteration; ++n) {
                RenderTexture temp2 = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, source.format);
                float offset = samplerOffset * (n * 2 + 1);
                material.SetVector(_offsetsId, new Vector4(offset, offset, 0, 0));
                Graphics.Blit(temp1, temp2, material, 1);

                offset = samplerOffset * (n * 2 + 2);
                material.SetVector(_offsetsId, new Vector4(offset, offset, 0, 0));
                Graphics.Blit(temp2, temp1, material, 1);
                RenderTexture.ReleaseTemporary(temp2);
            }

            material.SetTexture(_blurTexId, temp1);
            material.SetVector(_lightColorId, lightColor);
            material.SetFloat(_lightFactorId, lightFactor);

            // 最终混合，将体积光径向模糊图与原始图混合，pass2
            Graphics.Blit(source, destination, material, 2);

            RenderTexture.ReleaseTemporary(temp1);
        }
        else {
            Graphics.Blit(source, destination);
        }
    }
}
