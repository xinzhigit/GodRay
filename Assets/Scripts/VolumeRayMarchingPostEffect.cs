using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VolumeRayMarchingPostEffect : PostEffectBase {
    public int downSample = 1;
    public int sampleScale = 1;
    private RenderTexture _volumeLightRT = null;

    public void RegisterVolumeLightRT(RenderTexture rt) {
        _volumeLightRT = rt;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if(material && _volumeLightRT) {
            Graphics.Blit(_volumeLightRT, destination);
            // 申请RT, 并且分辨率按照downsample减低
            RenderTexture tempRT = RenderTexture.GetTemporary(_volumeLightRT.width >> downSample, _volumeLightRT.height >> downSample, 0, source.format);

            // 高斯模糊，两次模糊，横向纵向
            material.SetVector("_Offsets", new Vector4(0, sampleScale, 0, 0));
            Graphics.Blit(_volumeLightRT, tempRT, material, 0);
            material.SetVector("_Offsets", new Vector4(sampleScale, 0, 0, 0));
            Graphics.Blit(tempRT, _volumeLightRT, material, 0);

            // 使用pass1进行高斯模糊
            material.SetTexture("_VolumeLightTex", _volumeLightRT);
            Graphics.Blit(source, destination, material, 1);

            RenderTexture.ReleaseTemporary(tempRT);
        }
        else {
            Graphics.Blit(source, destination);
        }
    }
}
