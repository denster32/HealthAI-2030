#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// MARK: - Vertex Input/Output Structures

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// MARK: - Uniform Structures

struct FractalUniforms {
    float time;
    float heartRate;
    float heartRateVariability;
    float stressLevel;
    float zoom;
    float offsetX;
    float offsetY;
    int iterations;
    int colorMode;
};

struct VisualizationUniforms {
    float time;
    float amplitude;
    float frequency;
    float phase;
    float4 color;
};

// MARK: - Fractal Vertex Shader

vertex VertexOut fractal_vertex_main(const VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

// MARK: - Fractal Fragment Shader with Health Data Integration

fragment float4 fractal_fragment_main(
    VertexOut in [[stage_in]],
    constant FractalUniforms& uniforms [[buffer(0)]]
) {
    // Normalize coordinates to [-1, 1] range
    float2 coord = (in.texCoord - 0.5) * 2.0;
    
    // Apply zoom and offset
    coord = coord * uniforms.zoom + float2(uniforms.offsetX, uniforms.offsetY);
    
    // Health-influenced fractal parameters
    float heartRateInfluence = uniforms.heartRate / 100.0; // Normalize to [0, 1.5]
    float hrvInfluence = uniforms.heartRateVariability / 50.0; // Normalize to [0, 1]
    float stressInfluence = uniforms.stressLevel; // Already [0, 1]
    
    // Mandelbrot set with health data modulation
    float2 z = float2(0.0);
    float2 c = coord + float2(sin(uniforms.time * 0.1) * heartRateInfluence * 0.1,
                              cos(uniforms.time * 0.1) * hrvInfluence * 0.1);
    
    int iterations = 0;
    for (int i = 0; i < uniforms.iterations; i++) {
        if (length(z) > 2.0) break;
        
        // Add stress-influenced turbulence
        float2 noise = float2(
            sin(z.x * 5.0 + uniforms.time) * stressInfluence * 0.05,
            cos(z.y * 5.0 + uniforms.time) * stressInfluence * 0.05
        );
        
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c + noise;
        iterations++;
    }
    
    // Color mapping based on health data
    float intensity = float(iterations) / float(uniforms.iterations);
    
    float3 color;
    if (uniforms.colorMode == 0) {
        // Heart rate influenced colors (red spectrum)
        color = float3(
            intensity * heartRateInfluence,
            intensity * (1.0 - stressInfluence) * 0.5,
            intensity * hrvInfluence * 0.8
        );
    } else if (uniforms.colorMode == 1) {
        // Stress influenced colors (warmer = more stress)
        float hue = stressInfluence * 0.3 + intensity * 0.7; // 0.3 = orange-red range
        color = hsv_to_rgb(float3(hue, 0.8, intensity));
    } else {
        // HRV influenced colors (smoother gradients)
        color = float3(
            sin(intensity * 3.14159 * heartRateInfluence) * 0.5 + 0.5,
            sin(intensity * 3.14159 * hrvInfluence + 2.094) * 0.5 + 0.5,
            sin(intensity * 3.14159 * (1.0 - stressInfluence) + 4.188) * 0.5 + 0.5
        );
    }
    
    // Add time-based animation influenced by heart rate
    float pulse = sin(uniforms.time * heartRateInfluence * 2.0) * 0.1 + 0.9;
    color *= pulse;
    
    return float4(color, 1.0);
}

// MARK: - Fractal Compute Shader

kernel void fractal_compute_main(
    texture2d<float, access::write> outputTexture [[texture(0)]],
    constant FractalUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Check bounds
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    // Normalize coordinates
    float2 size = float2(outputTexture.get_width(), outputTexture.get_height());
    float2 coord = (float2(gid) / size - 0.5) * 2.0;
    
    // Apply transformations
    coord = coord * uniforms.zoom + float2(uniforms.offsetX, uniforms.offsetY);
    
    // Compute fractal (similar to fragment shader but optimized for compute)
    float2 z = float2(0.0);
    float2 c = coord;
    
    int iterations = 0;
    for (int i = 0; i < uniforms.iterations; i++) {
        if (length(z) > 2.0) break;
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        iterations++;
    }
    
    float intensity = float(iterations) / float(uniforms.iterations);
    
    // Health-influenced coloring
    float3 color = float3(
        intensity * (uniforms.heartRate / 100.0),
        intensity * (uniforms.heartRateVariability / 50.0),
        intensity * (1.0 - uniforms.stressLevel)
    );
    
    outputTexture.write(float4(color, 1.0), gid);
}

// MARK: - Heart Rate Visualization Shaders

fragment float4 heart_rate_waveform(
    VertexOut in [[stage_in]],
    constant float* heartRateData [[buffer(0)]],
    constant VisualizationUniforms& uniforms [[buffer(1)]]
) {
    float2 coord = in.texCoord;
    
    // Sample heart rate data
    int dataIndex = int(coord.x * 100); // Assuming 100 data points
    float heartRate = heartRateData[dataIndex];
    
    // Create waveform visualization
    float normalizedHeartRate = (heartRate - 60.0) / 40.0; // Normalize 60-100 BPM to 0-1
    float waveY = sin(coord.x * 6.28318 * uniforms.frequency + uniforms.phase) * normalizedHeartRate * uniforms.amplitude;
    
    // Create line visualization
    float lineThickness = 0.005;
    float dist = abs(coord.y - (0.5 + waveY * 0.3));
    float alpha = smoothstep(lineThickness, 0.0, dist);
    
    // Color based on heart rate intensity
    float3 color = mix(
        float3(0.0, 1.0, 0.0), // Green for normal
        float3(1.0, 0.0, 0.0), // Red for high
        normalizedHeartRate
    );
    
    return float4(color * alpha, alpha);
}

// MARK: - Sleep Stage Visualization Shaders

fragment float4 sleep_stage_transitions(
    VertexOut in [[stage_in]],
    constant VisualizationUniforms& uniforms [[buffer(0)]]
) {
    float2 coord = in.texCoord;
    
    // Create layered visualization for different sleep stages
    float time = uniforms.time;
    
    // Deep sleep layer (bottom, dark blue)
    float deepSleep = smoothstep(0.0, 0.3, 1.0 - coord.y) * 
                      (sin(coord.x * 10.0 + time * 0.1) * 0.1 + 0.9);
    
    // Light sleep layer (middle, lighter blue)
    float lightSleep = smoothstep(0.2, 0.6, 1.0 - coord.y) * 
                       smoothstep(0.6, 0.2, 1.0 - coord.y) *
                       (sin(coord.x * 15.0 + time * 0.2) * 0.2 + 0.8);
    
    // REM sleep layer (upper middle, purple)
    float remSleep = smoothstep(0.5, 0.8, 1.0 - coord.y) * 
                     smoothstep(0.8, 0.5, 1.0 - coord.y) *
                     (sin(coord.x * 20.0 + time * 0.3) * 0.3 + 0.7);
    
    // Awake layer (top, yellow/orange)
    float awake = smoothstep(0.7, 1.0, 1.0 - coord.y) *
                  (sin(coord.x * 25.0 + time * 0.5) * 0.4 + 0.6);
    
    // Combine layers with appropriate colors
    float3 color = float3(0.0);
    color += float3(0.0, 0.0, 0.5) * deepSleep;      // Dark blue
    color += float3(0.2, 0.4, 0.8) * lightSleep;     // Light blue
    color += float3(0.6, 0.2, 0.8) * remSleep;       // Purple
    color += float3(1.0, 0.8, 0.3) * awake;          // Yellow/orange
    
    return float4(color, 1.0);
}

// MARK: - Health Data Visualization Shader

fragment float4 health_data_visualization(
    VertexOut in [[stage_in]],
    constant VisualizationUniforms& uniforms [[buffer(0)]]
) {
    float2 coord = in.texCoord;
    float time = uniforms.time;
    
    // Create particle-based visualization for health metrics
    float3 color = float3(0.0);
    
    // Heart rate particles (red)
    for (int i = 0; i < 20; i++) {
        float2 particlePos = float2(
            fmod(float(i) * 0.1 + time * 0.1, 1.0),
            sin(float(i) + time) * 0.3 + 0.5
        );
        
        float dist = distance(coord, particlePos);
        float intensity = 1.0 / (1.0 + dist * 100.0);
        color += float3(1.0, 0.0, 0.0) * intensity;
    }
    
    // Stress level background gradient
    float stressGradient = smoothstep(0.0, 1.0, coord.y) * uniforms.amplitude;
    color += float3(stressGradient * 0.3, 0.0, 0.0);
    
    // HRV oscillations (blue)
    float hrv = sin(coord.x * 20.0 + time * 2.0) * cos(coord.y * 15.0 + time * 1.5);
    color += float3(0.0, 0.0, hrv * 0.3 + 0.1);
    
    return float4(color, 1.0);
}

// MARK: - Utility Functions

float3 hsv_to_rgb(float3 hsv) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
}

float noise(float2 coord) {
    return fract(sin(dot(coord, float2(12.9898, 78.233))) * 43758.5453);
}

float smooth_noise(float2 coord) {
    float2 i = floor(coord);
    float2 f = fract(coord);
    
    float a = noise(i);
    float b = noise(i + float2(1.0, 0.0));
    float c = noise(i + float2(0.0, 1.0));
    float d = noise(i + float2(1.0, 1.0));
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}