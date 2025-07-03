#include <metal_stdlib>
using namespace metal;

// Reverb Kernel
kernel void reverbKernel(
    const device float *inAudio [[buffer(0)]],
    device float *outAudio [[buffer(1)]],
    uint id [[thread_position_in_grid]],
    uint bufferSize [[buffer(2)]]
) {
    if (id >= bufferSize) { return; }

    // Simple feedback delay network (FDN) for reverb
    // This is a highly simplified example. A real reverb would be much more complex.
    // For demonstration, we'll use a basic comb filter.

    float inputSample = inAudio[id];
    float outputSample = inputSample;

    // Example: Add a delayed, attenuated version of the input back to the output
    // This simulates a single reflection.
    // In a real FDN, multiple delay lines and feedback loops would be used.
    
    // Parameters (simplified for Metal kernel)
    float delayTime = 0.05; // seconds
    float decay = 0.7;      // feedback gain

    uint delaySamples = uint(delayTime * 48000.0); // Assuming 48kHz sample rate

    if (id >= delaySamples) {
        outputSample += inAudio[id - delaySamples] * decay;
    }

    outAudio[id] = outputSample;
}

// Delay Kernel
kernel void delayKernel(
    const device float *inAudio [[buffer(0)]],
    device float *outAudio [[buffer(1)]],
    uint id [[thread_position_in_grid]],
    uint bufferSize [[buffer(2)]]
) {
    if (id >= bufferSize) { return; }

    // Simple delay effect
    float inputSample = inAudio[id];
    float outputSample = inputSample;

    // Parameters
    float delayTime = 0.3; // seconds
    float feedback = 0.5;  // feedback gain
    float wetMix = 0.5;    // mix of delayed signal

    uint delaySamples = uint(delayTime * 48000.0); // Assuming 48kHz sample rate

    if (id >= delaySamples) {
        float delayedSample = inAudio[id - delaySamples];
        outputSample = inputSample + delayedSample * wetMix;
        // For a true feedback delay, you'd need to manage a circular buffer
        // within the kernel or pass state, which is more complex for a simple compute kernel.
        // This example is a feed-forward delay.
    }

    outAudio[id] = outputSample;
}