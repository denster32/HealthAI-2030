#include <metal_stdlib>
using namespace metal;

struct FractalParameters {
    int fractalType;
    float zoom;
    float centerX;
    float centerY;
    int iterations;
    float colorShift;
    int colorMode;
    float morphingSpeed;
    float timeOffset;
    float biometricInfluence;
};

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Vertex Shader
vertex VertexOut vertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = in.position;
    out.texCoord = in.texCoord;
    return out;
}

// Fragment Shader
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                              texture2d<float> fractalTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = fractalTexture.sample(textureSampler, in.texCoord);
    return color;
}

// Helper function to generate colors based on iteration count and color scheme
float4 generateColor(int iterations, int maxIterations, float colorShift, int colorMode, float biometricInfluence) {
    if (iterations == maxIterations) {
        return float4(0.0, 0.0, 0.0, 1.0); // Black for points in the set
    }
    
    float t = float(iterations) / float(maxIterations);
    t = pow(t, 0.5); // Adjust color distribution
    
    // Apply biometric influence to color intensity
    t = t * (0.5 + 0.5 * biometricInfluence);
    
    // Apply color shift
    t = fmod(t + colorShift / 360.0, 1.0);
    
    float4 color;
    
    switch (colorMode) {
        case 0: // Health color scheme
            color = float4(
                0.2 + 0.8 * sin(t * 3.14159 * 2.0),
                0.3 + 0.7 * sin(t * 3.14159 * 4.0 + 2.0),
                0.4 + 0.6 * sin(t * 3.14159 * 6.0 + 4.0),
                1.0
            );
            break;
            
        case 1: // Rainbow color scheme
            color = float4(
                0.5 + 0.5 * sin(t * 3.14159 * 6.0),
                0.5 + 0.5 * sin(t * 3.14159 * 6.0 + 2.0),
                0.5 + 0.5 * sin(t * 3.14159 * 6.0 + 4.0),
                1.0
            );
            break;
            
        case 2: // Ocean color scheme
            color = float4(
                0.1 + 0.4 * t,
                0.3 + 0.6 * t,
                0.5 + 0.5 * t,
                1.0
            );
            break;
            
        case 3: // Sunset color scheme
            color = float4(
                0.8 + 0.2 * sin(t * 3.14159 * 2.0),
                0.4 + 0.4 * sin(t * 3.14159 * 3.0),
                0.2 + 0.3 * sin(t * 3.14159 * 4.0),
                1.0
            );
            break;
            
        case 4: // Forest color scheme
            color = float4(
                0.2 + 0.6 * sin(t * 3.14159 * 2.0),
                0.4 + 0.6 * sin(t * 3.14159 * 2.0 + 1.0),
                0.1 + 0.3 * sin(t * 3.14159 * 3.0),
                1.0
            );
            break;
            
        case 5: // Cosmic color scheme
            color = float4(
                0.3 + 0.7 * sin(t * 3.14159 * 3.0),
                0.1 + 0.4 * sin(t * 3.14159 * 2.0),
                0.5 + 0.5 * sin(t * 3.14159 * 4.0),
                1.0
            );
            break;
            
        default:
            color = float4(t, t, t, 1.0);
            break;
    }
    
    return color;
}

// Mandelbrot fractal calculation
int mandelbrot(float2 c, int maxIterations, float timeOffset, float biometricInfluence) {
    float2 z = float2(0.0, 0.0);
    int iterations = 0;
    
    // Apply biometric influence to the calculation
    float2 biometricOffset = float2(sin(timeOffset) * biometricInfluence * 0.1, cos(timeOffset) * biometricInfluence * 0.1);
    c += biometricOffset;
    
    while (iterations < maxIterations && length(z) < 2.0) {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        iterations++;
    }
    
    return iterations;
}

// Julia fractal calculation
int julia(float2 z, int maxIterations, float timeOffset, float biometricInfluence) {
    // Julia set constant influenced by biometrics
    float2 c = float2(-0.7269 + sin(timeOffset) * biometricInfluence * 0.1, 0.1889 + cos(timeOffset) * biometricInfluence * 0.1);
    int iterations = 0;
    
    while (iterations < maxIterations && length(z) < 2.0) {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        iterations++;
    }
    
    return iterations;
}

// Burning Ship fractal calculation
int burningShip(float2 c, int maxIterations, float timeOffset, float biometricInfluence) {
    float2 z = float2(0.0, 0.0);
    int iterations = 0;
    
    // Apply biometric influence
    float2 biometricOffset = float2(sin(timeOffset) * biometricInfluence * 0.05, cos(timeOffset) * biometricInfluence * 0.05);
    c += biometricOffset;
    
    while (iterations < maxIterations && length(z) < 2.0) {
        z = float2(abs(z.x) * abs(z.x) - abs(z.y) * abs(z.y), 2.0 * abs(z.x) * abs(z.y)) + c;
        iterations++;
    }
    
    return iterations;
}

// Newton fractal calculation
int newton(float2 z, int maxIterations, float timeOffset, float biometricInfluence) {
    int iterations = 0;
    
    // Apply biometric influence to the starting point
    z += float2(sin(timeOffset) * biometricInfluence * 0.1, cos(timeOffset) * biometricInfluence * 0.1);
    
    while (iterations < maxIterations) {
        // Newton's method for z^3 - 1 = 0
        float2 z2 = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y);
        float2 z3 = float2(z2.x * z.x - z2.y * z.y, z2.x * z.y + z2.y * z.x);
        
        float2 numerator = z3 - float2(1.0, 0.0);
        float2 denominator = 3.0 * z2;
        
        // Complex division
        float denomSqr = denominator.x * denominator.x + denominator.y * denominator.y;
        if (denomSqr < 1e-6) break;
        
        float2 quotient = float2(
            (numerator.x * denominator.x + numerator.y * denominator.y) / denomSqr,
            (numerator.y * denominator.x - numerator.x * denominator.y) / denomSqr
        );
        
        z = z - quotient;
        
        if (length(quotient) < 1e-6) break;
        
        iterations++;
    }
    
    return iterations;
}

// Tricorn fractal calculation
int tricorn(float2 c, int maxIterations, float timeOffset, float biometricInfluence) {
    float2 z = float2(0.0, 0.0);
    int iterations = 0;
    
    // Apply biometric influence
    float2 biometricOffset = float2(sin(timeOffset) * biometricInfluence * 0.08, cos(timeOffset) * biometricInfluence * 0.08);
    c += biometricOffset;
    
    while (iterations < maxIterations && length(z) < 2.0) {
        // Tricorn uses complex conjugate
        z = float2(z.x * z.x - z.y * z.y, -2.0 * z.x * z.y) + c;
        iterations++;
    }
    
    return iterations;
}

// Main compute kernel for fractal generation
kernel void generateFractal(texture2d<float, access::write> outputTexture [[texture(0)]],
                           constant FractalParameters& params [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    uint width = outputTexture.get_width();
    uint height = outputTexture.get_height();
    
    if (gid.x >= width || gid.y >= height) return;
    
    // Convert pixel coordinates to complex plane coordinates
    float2 uv = float2(gid) / float2(width, height);
    uv = uv * 2.0 - 1.0; // Map to [-1, 1]
    uv.x *= float(width) / float(height); // Correct aspect ratio
    
    // Apply zoom and center
    uv = uv / params.zoom + float2(params.centerX, params.centerY);
    
    int iterations = 0;
    
    // Calculate fractal based on type
    switch (params.fractalType) {
        case 0: // Mandelbrot
            iterations = mandelbrot(uv, params.iterations, params.timeOffset, params.biometricInfluence);
            break;
            
        case 1: // Julia
            iterations = julia(uv, params.iterations, params.timeOffset, params.biometricInfluence);
            break;
            
        case 2: // Burning Ship
            iterations = burningShip(uv, params.iterations, params.timeOffset, params.biometricInfluence);
            break;
            
        case 3: // Newton
            iterations = newton(uv, params.iterations, params.timeOffset, params.biometricInfluence);
            break;
            
        case 4: // Tricorn
            iterations = tricorn(uv, params.iterations, params.timeOffset, params.biometricInfluence);
            break;
            
        default:
            iterations = mandelbrot(uv, params.iterations, params.timeOffset, params.biometricInfluence);
            break;
    }
    
    // Generate color based on iterations
    float4 color = generateColor(iterations, params.iterations, params.colorShift, params.colorMode, params.biometricInfluence);
    
    // Write pixel to output texture
    outputTexture.write(color, gid);
}

// Additional compute kernel for real-time biometric morphing
kernel void morphFractal(texture2d<float, access::read> inputTexture [[texture(0)]],
                        texture2d<float, access::write> outputTexture [[texture(1)]],
                        constant FractalParameters& params [[buffer(0)]],
                        uint2 gid [[thread_position_in_grid]]) {
    
    uint width = outputTexture.get_width();
    uint height = outputTexture.get_height();
    
    if (gid.x >= width || gid.y >= height) return;
    
    // Read original pixel
    float4 originalColor = inputTexture.read(gid);
    
    // Apply biometric morphing effects
    float2 uv = float2(gid) / float2(width, height);
    
    // Create breathing effect based on biometric influence
    float breathingEffect = sin(params.timeOffset * 2.0) * params.biometricInfluence * 0.1;
    float2 offset = float2(sin(uv.y * 10.0 + params.timeOffset) * breathingEffect,
                          cos(uv.x * 10.0 + params.timeOffset) * breathingEffect);
    
    // Sample with offset for morphing effect
    float2 morphedUV = uv + offset;
    morphedUV = clamp(morphedUV, 0.0, 1.0);
    
    uint2 morphedGid = uint2(morphedUV * float2(width, height));
    morphedGid = clamp(morphedGid, uint2(0), uint2(width - 1, height - 1));
    
    float4 morphedColor = inputTexture.read(morphedGid);
    
    // Blend original and morphed colors based on biometric influence
    float4 finalColor = mix(originalColor, morphedColor, params.biometricInfluence * 0.5);
    
    // Apply color intensity modulation
    finalColor.rgb *= (0.8 + 0.4 * params.biometricInfluence);
    
    outputTexture.write(finalColor, gid);
}

// Compute kernel for 3D fractal generation (for RealityKit integration)
kernel void generate3DFractal(texture3d<float, access::write> outputTexture [[texture(0)]],
                             constant FractalParameters& params [[buffer(0)]],
                             uint3 gid [[thread_position_in_grid]]) {
    
    uint width = outputTexture.get_width();
    uint height = outputTexture.get_height();
    uint depth = outputTexture.get_depth();
    
    if (gid.x >= width || gid.y >= height || gid.z >= depth) return;
    
    // Convert 3D coordinates to complex plane with depth influence
    float3 uvw = float3(gid) / float3(width, height, depth);
    uvw = uvw * 2.0 - 1.0; // Map to [-1, 1]
    
    // Use Z coordinate to influence the fractal calculation
    float2 uv = uvw.xy / params.zoom + float2(params.centerX, params.centerY);
    float depthInfluence = uvw.z * params.biometricInfluence;
    
    // Modify fractal parameters based on depth
    int depthIterations = int(float(params.iterations) * (1.0 + depthInfluence));
    float depthColorShift = params.colorShift + depthInfluence * 180.0;
    
    // Calculate 3D Mandelbrot (Mandelbulb approximation)
    int iterations = mandelbrot(uv + float2(depthInfluence * 0.1), depthIterations, params.timeOffset, params.biometricInfluence);
    
    // Generate color with depth influence
    float4 color = generateColor(iterations, depthIterations, depthColorShift, params.colorMode, params.biometricInfluence);
    
    // Apply depth-based alpha for volume rendering
    color.a = color.a * (1.0 - abs(uvw.z) * 0.5);
    
    outputTexture.write(color, gid);
}