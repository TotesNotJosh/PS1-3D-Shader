using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class PS1ShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // Find properties
        MaterialProperty useIntFog = FindProperty("_UseIntFog", properties);
        MaterialProperty fogSteps = FindProperty("_FogSteps", properties);

        // Draw default properties
        foreach (MaterialProperty property in properties)
        {
            if (property.name == "_FogSteps") {
                // Only show _FogSteps if _UseIntFog is enabled
                if (useIntFog.floatValue != 0.0f)
                {
                    materialEditor.ShaderProperty(property, property.displayName);
                }
            } else {
                materialEditor.ShaderProperty(property, property.displayName);
            }
        }
    }
}
