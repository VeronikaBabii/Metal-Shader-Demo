//
//  Shaders.metal
//  Impressit-Test-Task
//
//  Created by Veronika Babii on 17.10.2023.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// MARK: - Structures

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float3 normal [[attribute(2)]];
    float4 color [[attribute(3)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float3 normal;
    float pointSize [[point_size]];
    float4 color;
    float3 originalPosition;
};

struct Light {
    float3 position;
    float3 color;
    float intensity;
};

struct Uniforms {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

// MARK: - Vertex shader

vertex VertexOut customVertexShader(VertexIn vertexIn [[stage_in]],
                                    constant Uniforms& uniforms [[buffer(0)]])
{
    float4 modelSpacePosition = float4(vertexIn.position, 1.0);
    
    VertexOut outVertex;
    
    outVertex.texCoord = vertexIn.texCoord;
    outVertex.normal = normalize(vertexIn.normal);
    outVertex.pointSize = 1.0;
    outVertex.color = vertexIn.color;
    outVertex.originalPosition = vertexIn.position;
    
    outVertex.position = modelSpacePosition;
//    outVertex.position = uniforms.projectionMatrix * uniforms.viewMatrix * modelSpacePosition;
    
    return outVertex;
}

// MARK: - Fragment shader

fragment float4 customFragmentShader(VertexOut inVertex [[stage_in]],
                                     constant Light& light [[buffer(0)]])
{
    
    // Calculate vector from surface point to light source.
    float3 surfaceToLightVector = light.position - inVertex.originalPosition;
    
    // Calculate distance between surface point and light source.
    float distance = length(surfaceToLightVector);
    
    // Normalize vector.
//    float3 normalizedSurfaceToLight = normalize(surfaceToLightVector);
    
    // Set how quickly light intensity diminishes with distance.
    float adjustedLightIntensity = 0.7;
    float attenuationFactor = 0.2;
    float attenuation = 1.0 / (1.0 + attenuationFactor * distance * distance);
    
    attenuation *= adjustedLightIntensity;
    attenuation = clamp(attenuation, 0.0, 1.0);
    float3 litColor = light.color * attenuation;
    
    // Calculate influence of ambient lighting.
    float ambientIntensity = 0.3;
    float3 ambientColor = float3(1, 1, 1) * ambientIntensity; // white
    
    // Combine ambient light with light source.
    float3 combinedLight = ambientColor + litColor;
    
    float originalColorWeight = 0.5;
    
    // Mix colors.
    float3 finalColor = mix(combinedLight, inVertex.color.rgb, originalColorWeight);
    
    return float4(finalColor, 1.0);
}
