using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class RayMarchingPointLight : MonoBehaviour {
    private Material _lightMaterial;
    private Light _lightComponent;
    private Texture2D _ditherMap;
    private CommandBuffer _commandBuffer;
    private static RenderTexture _volumeLightRT;
    private Renderer _lightRenderer;

    // Mie-Scattering g参数
    [Range(0.0f, 0.99f)]
    public float MieScatteringG = 0.0f;

    private void OnEnable() {
        if(Camera.main != null) {
            Camera.main.depthTextureMode = DepthTextureMode.Depth;
        }

        Init();
        _lightComponent.AddCommandBuffer(LightEvent.AfterShadowMap, _commandBuffer);
    }

    private void OnDestroy() {
        _lightComponent.RemoveCommandBuffer(LightEvent.AfterShadowMap, _commandBuffer);
        if(Camera.main != null) {
            Camera.main.depthTextureMode = DepthTextureMode.None;
        }
    }

    private void Update() {
        if(_lightMaterial == null || _lightComponent == null) {
            return;
        }

        Matrix4x4 lightMatrix = Matrix4x4.TRS(transform.position, transform.rotation, Vector3.one).inverse;
        float scale = _lightComponent.range * 2.0f;
        transform.localScale = new Vector3(scale, scale, scale);

        _lightMaterial.EnableKeyword("POINT");
        if(_lightComponent.shadows == LightShadows.None) {
            _lightMaterial.DisableKeyword("SHADOW_CUBE");
        }
        else {
            _lightMaterial.EnableKeyword("SHADOW_CUBE");
        }

        float g2 = MieScatteringG * MieScatteringG;
        float lightRange = _lightComponent.range;
        _lightMaterial.SetMatrix("_lightMatrix", lightMatrix);
        _lightMaterial.SetVector("_VolumeLightPos", transform.position);

        Vector4 mieScatteringFactor = Vector4.zero;
        mieScatteringFactor.x = (1 - g2) * 0.25f / Mathf.PI;
        mieScatteringFactor.y = 1 + g2;
        mieScatteringFactor.z = 2 * MieScatteringG;
        mieScatteringFactor.w = 1.0f / (lightRange * lightRange);
        _lightMaterial.SetVector("_MieScatteringFactor", mieScatteringFactor);
        _lightMaterial.SetTexture("_DitherMap", _ditherMap);

        // 自己计算MVP矩阵传给shader，用Camera.main可能导致编辑器Scene窗口显示有问题
        Matrix4x4 worldMatrix = transform.localToWorldMatrix;
        Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(Camera.main.projectionMatrix, true);
        Matrix4x4 mvpMatrix = projMatrix * Camera.main.worldToCameraMatrix * worldMatrix;
        _lightMaterial.SetMatrix("_CustomMVP", mvpMatrix);
    }

    private void Init() {
        InitVolumeLight();
        InitCommandBuffer();
        InitPostEffectComponent();
    }

    private void InitVolumeLight() {
        _lightRenderer = GetComponent<Renderer>();
        _lightMaterial = _lightRenderer.sharedMaterial;
        _lightComponent = GetComponent<Light>();
        if(_lightComponent) {
            _lightComponent = gameObject.AddComponent<Light>();
        }
        _lightComponent.shadows = LightShadows.Hard;
        _lightComponent.enabled = false;
        if(_ditherMap == null) {
            _ditherMap = GenerateDitherMap();
        }
        if(_volumeLightRT == null) {
            _volumeLightRT = new RenderTexture(512, 512, 16);
        }
    }

    private void InitCommandBuffer() {
        if(_commandBuffer == null) {
            _commandBuffer = new CommandBuffer();
        }
        _commandBuffer.Clear();
        _commandBuffer.name = "RayMarchingPointLight";
        _commandBuffer.SetGlobalTexture("_ShadowMapTexture", BuiltinRenderTextureType.CurrentActive);
        _commandBuffer.SetRenderTarget(_volumeLightRT);
        _commandBuffer.ClearRenderTarget(true, true, Color.black);
        _commandBuffer.DrawRenderer(_lightRenderer, _lightMaterial);
    }

    private void InitPostEffectComponent() {
        if(Camera.main == null) {
            return;
        }

        var postEffect = Camera.main.gameObject.GetComponent<VolumeRayMarchingPostEffect>();
        if(postEffect == null) {
            postEffect = Camera.main.gameObject.AddComponent<VolumeRayMarchingPostEffect>();
        }

        postEffect.RegisterVolumeLightRT(_volumeLightRT);
        postEffect.shader = Shader.Find("Custom/RayMarchingPointLight");
    }

    private Texture2D GenerateDitherMap() {
        int texSize = 4;
        var ditherMap = new Texture2D(texSize, texSize, TextureFormat.Alpha8, false, true);
        ditherMap.filterMode = FilterMode.Point;
        Color32[] colors = new Color32[texSize * texSize];

        colors[0] = GetDitherColor(0.0f);
        colors[1] = GetDitherColor(8.0f);
        colors[2] = GetDitherColor(2.0f);
        colors[3] = GetDitherColor(10.0f);

        colors[4] = GetDitherColor(12.0f);
        colors[5] = GetDitherColor(4.0f);
        colors[6] = GetDitherColor(14.0f);
        colors[7] = GetDitherColor(6.0f);

        colors[8] = GetDitherColor(3.0f);
        colors[9] = GetDitherColor(11.0f);
        colors[10] = GetDitherColor(1.0f);
        colors[11] = GetDitherColor(9.0f);

        colors[12] = GetDitherColor(15.0f);
        colors[13] = GetDitherColor(7.0f);
        colors[14] = GetDitherColor(13.0f);
        colors[15] = GetDitherColor(5.0f);

        ditherMap.SetPixels32(colors);
        ditherMap.Apply();

        return ditherMap;
    }

    private Color32 GetDitherColor(float value) {
        byte byteValue = (byte)(value / 16.0f * 255);
        return new Color32(byteValue, byteValue, byteValue, byteValue);
    }
}
