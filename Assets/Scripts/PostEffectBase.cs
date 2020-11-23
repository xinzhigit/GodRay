using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffectBase : MonoBehaviour {
    [Header("后处理Shader")]
    public Shader shader = null;

    private Material _material = null;
    public Material material {
        get {
            if(_material == null) {
                _material = GenerateMaterial(shader);
            }
            return _material;
        }
    }

    protected Material GenerateMaterial(Shader shader) {
        if(shader == null || shader.isSupported == false) {
            return null;
        }

        Material mat = new Material(shader);
        mat.hideFlags = HideFlags.DontSave;

        return mat;
    }
}
