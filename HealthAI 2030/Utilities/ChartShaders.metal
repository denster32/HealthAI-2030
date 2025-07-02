#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex and Fragment Structures

struct ChartVertex {
    float2 position;
    float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 texCoord;
};

struct LineChartUniforms {
    float4 color;
    float lineWidth;
    float smoothing;
    float animation;
};

struct BarChartUniforms {
    float4 barColor;
    float4 borderColor;
    float barSpacing;
    float cornerRadius;
    float animation;
};

struct AreaChartUniforms {
    float4 fillColor;
    float4 strokeColor;
    float gradient;
    float opacity;
    float animation;
};

struct RealTimeChartUniforms {
    float4 lineColor;
    float4 backgroundColor;
    float scrollSpeed;
    float fadeEffect;
    float timeWindow;
};

// MARK: - Line Chart Shaders

vertex VertexOut lineChartVertex(uint vertexID [[vertex_id]],
                                constant ChartVertex* vertices [[buffer(0)]],
                                constant LineChartUniforms& uniforms [[buffer(1)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    // Transform to normalized device coordinates (-1 to 1)
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    out.color = vertex.color * uniforms.color;
    out.texCoord = vertex.position;
    
    // Apply animation scaling
    out.position.xy *= uniforms.animation;
    
    return out;
}

fragment float4 lineChartFragment(VertexOut in [[stage_in]],
                                 constant LineChartUniforms& uniforms [[buffer(0)]]) {
    
    float4 color = in.color;
    
    // Apply smoothing anti-aliasing
    if (uniforms.smoothing > 0.5) {
        float2 center = in.texCoord - 0.5;
        float distance = length(center);
        float alpha = smoothstep(0.48, 0.52, 1.0 - distance);
        color.a *= alpha;
    }
    
    return color;
}

// MARK: - Bar Chart Shaders

vertex VertexOut barChartVertex(uint vertexID [[vertex_id]],
                               constant ChartVertex* vertices [[buffer(0)]],
                               constant BarChartUniforms& uniforms [[buffer(1)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    // Transform to normalized device coordinates
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    out.color = vertex.color * uniforms.barColor;
    out.texCoord = vertex.position;
    
    // Apply animation - grow from bottom
    out.position.y *= uniforms.animation;
    
    return out;
}

fragment float4 barChartFragment(VertexOut in [[stage_in]],
                                constant BarChartUniforms& uniforms [[buffer(0)]]) {
    
    float4 color = in.color;
    
    // Apply corner radius effect
    if (uniforms.cornerRadius > 0.0) {
        float2 coord = in.texCoord;
        float2 center = float2(0.5, 0.5);
        float2 distance = abs(coord - center);
        
        // Calculate corner radius mask
        float cornerMask = 1.0;
        if (distance.x > 0.5 - uniforms.cornerRadius && distance.y > 0.5 - uniforms.cornerRadius) {
            float2 cornerDistance = distance - (0.5 - uniforms.cornerRadius);
            float cornerRadius = length(cornerDistance);
            cornerMask = 1.0 - smoothstep(uniforms.cornerRadius - 0.01, uniforms.cornerRadius, cornerRadius);
        }
        
        color.a *= cornerMask;
    }
    
    return color;
}

// MARK: - Area Chart Shaders

vertex VertexOut areaChartVertex(uint vertexID [[vertex_id]],
                                constant ChartVertex* vertices [[buffer(0)]],
                                constant AreaChartUniforms& uniforms [[buffer(1)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    // Transform to normalized device coordinates
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    out.color = vertex.color * uniforms.fillColor;
    out.texCoord = vertex.position;
    
    // Apply animation
    out.position.y *= uniforms.animation;
    
    return out;
}

fragment float4 areaChartFragment(VertexOut in [[stage_in]],
                                 constant AreaChartUniforms& uniforms [[buffer(0)]]) {
    
    float4 color = in.color;
    
    // Apply gradient effect
    if (uniforms.gradient > 0.5) {
        float gradientFactor = in.texCoord.y;
        color.rgb = mix(color.rgb * 0.3, color.rgb, gradientFactor);
    }
    
    // Apply overall opacity
    color.a *= uniforms.opacity;
    
    return color;
}

// MARK: - Real-Time Chart Shaders

vertex VertexOut realTimeChartVertex(uint vertexID [[vertex_id]],
                                    constant ChartVertex* vertices [[buffer(0)]],
                                    constant RealTimeChartUniforms& uniforms [[buffer(1)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    // Transform to normalized device coordinates
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    out.color = vertex.color * uniforms.lineColor;
    out.texCoord = vertex.position;
    
    return out;
}

fragment float4 realTimeChartFragment(VertexOut in [[stage_in]],
                                     constant RealTimeChartUniforms& uniforms [[buffer(0)]]) {
    
    float4 color = in.color;
    
    // Apply fade effect based on time position
    if (uniforms.fadeEffect > 0.5) {
        float fadeAlpha = in.texCoord.x; // Fade from left to right
        color.a *= fadeAlpha;
    }
    
    return color;
}

// MARK: - Advanced Chart Effects Shaders

vertex VertexOut glowEffectVertex(uint vertexID [[vertex_id]],
                                 constant ChartVertex* vertices [[buffer(0)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    out.color = vertex.color;
    out.texCoord = vertex.position;
    
    return out;
}

fragment float4 glowEffectFragment(VertexOut in [[stage_in]]) {
    float4 color = in.color;
    
    // Create glow effect
    float2 center = in.texCoord - 0.5;
    float distance = length(center);
    float glow = exp(-distance * 3.0) * 0.5;
    
    color.rgb += glow;
    color.a = max(color.a, glow * 0.3);
    
    return color;
}

// MARK: - Health Data Visualization Shaders

vertex VertexOut heartRateVisualizationVertex(uint vertexID [[vertex_id]],
                                             constant ChartVertex* vertices [[buffer(0)]],
                                             constant float& time [[buffer(1)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    // Add heart beat pulse effect
    float pulse = sin(time * 8.0) * 0.1 + 1.0;
    
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    out.position.y *= pulse; // Apply pulse to y-axis
    
    // Color based on heart rate intensity
    float intensity = vertex.position.y;
    out.color = float4(intensity, 1.0 - intensity * 0.5, 0.2, 1.0);
    out.texCoord = vertex.position;
    
    return out;
}

fragment float4 heartRateVisualizationFragment(VertexOut in [[stage_in]]) {
    return in.color;
}

vertex VertexOut sleepStageVisualizationVertex(uint vertexID [[vertex_id]],
                                              constant ChartVertex* vertices [[buffer(0)]],
                                              constant float& sleepStage [[buffer(1)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    
    // Color based on sleep stage
    // 0: Awake (red), 1: Light (yellow), 2: Deep (blue), 3: REM (purple)
    float stage = sleepStage;
    if (stage < 1.0) {
        // Awake to Light sleep
        out.color = mix(float4(1.0, 0.3, 0.3, 1.0), float4(1.0, 1.0, 0.3, 1.0), stage);
    } else if (stage < 2.0) {
        // Light to Deep sleep
        out.color = mix(float4(1.0, 1.0, 0.3, 1.0), float4(0.3, 0.3, 1.0, 1.0), stage - 1.0);
    } else {
        // Deep to REM sleep
        out.color = mix(float4(0.3, 0.3, 1.0, 1.0), float4(0.8, 0.3, 1.0, 1.0), stage - 2.0);
    }
    
    out.texCoord = vertex.position;
    
    return out;
}

fragment float4 sleepStageVisualizationFragment(VertexOut in [[stage_in]]) {
    return in.color;
}

// MARK: - Interactive Chart Shaders

vertex VertexOut interactiveChartVertex(uint vertexID [[vertex_id]],
                                       constant ChartVertex* vertices [[buffer(0)]],
                                       constant float2& touchPosition [[buffer(1)]],
                                       constant float& interactionRadius [[buffer(2)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    
    // Calculate distance from touch
    float distance = length(vertex.position - touchPosition);
    float interaction = 1.0 - smoothstep(0.0, interactionRadius, distance);
    
    // Scale and brighten vertices near touch
    out.position.xy *= (1.0 + interaction * 0.2);
    out.color = vertex.color * (1.0 + interaction * 0.5);
    out.texCoord = vertex.position;
    
    return out;
}

fragment float4 interactiveChartFragment(VertexOut in [[stage_in]]) {
    return in.color;
}

// MARK: - Performance Optimized Shaders

vertex VertexOut optimizedChartVertex(uint vertexID [[vertex_id]],
                                     constant ChartVertex* vertices [[buffer(0)]],
                                     constant float4x4& mvpMatrix [[buffer(1)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    // Use matrix transformation for better performance
    float4 position = float4(vertex.position, 0.0, 1.0);
    out.position = mvpMatrix * position;
    out.color = vertex.color;
    out.texCoord = vertex.position;
    
    return out;
}

fragment float4 optimizedChartFragment(VertexOut in [[stage_in]],
                                      constant float& opacity [[buffer(0)]]) {
    
    float4 color = in.color;
    color.a *= opacity;
    
    return color;
}

// MARK: - Multi-Series Chart Shaders

vertex VertexOut multiSeriesChartVertex(uint vertexID [[vertex_id]],
                                       constant ChartVertex* vertices [[buffer(0)]],
                                       constant float4* seriesColors [[buffer(1)]],
                                       constant uint& seriesIndex [[buffer(2)]]) {
    
    ChartVertex vertex = vertices[vertexID];
    VertexOut out;
    
    out.position = float4(vertex.position.x * 2.0 - 1.0, vertex.position.y * 2.0 - 1.0, 0.0, 1.0);
    out.color = vertex.color * seriesColors[seriesIndex];
    out.texCoord = vertex.position;
    
    return out;
}

fragment float4 multiSeriesChartFragment(VertexOut in [[stage_in]]) {
    return in.color;
}