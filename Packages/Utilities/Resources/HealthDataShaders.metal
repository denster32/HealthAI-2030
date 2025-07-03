#include <metal_stdlib>
using namespace metal;

// MARK: - Heart Rate Analysis Kernel

kernel void analyzeHeartRateVariability(constant float* input [[buffer(0)]],
                                       device float* output [[buffer(1)]],
                                       constant uint& count [[buffer(2)]],
                                       uint index [[thread_position_in_grid]]) {
    
    if (index >= count) return;
    
    // Use first thread to calculate aggregated metrics
    if (index == 0) {
        float sum = 0.0;
        float min_hr = input[0];
        float max_hr = input[0];
        float sum_squared_diffs = 0.0;
        uint irregular_count = 0;
        
        // Calculate basic statistics
        for (uint i = 0; i < count; i++) {
            float hr = input[i];
            sum += hr;
            min_hr = min(min_hr, hr);
            max_hr = max(max_hr, hr);
            
            // Check for irregular rhythm (sudden changes > 20 BPM)
            if (i > 0 && abs(hr - input[i-1]) > 20.0) {
                irregular_count++;
            }
        }
        
        float avg_hr = sum / float(count);
        
        // Calculate HRV (RMSSD approximation)
        for (uint i = 1; i < count; i++) {
            float diff = input[i] - input[i-1];
            sum_squared_diffs += diff * diff;
        }
        
        float hrv = sqrt(sum_squared_diffs / float(count - 1));
        
        // Calculate resting heart rate (average of first 20% of data)
        float resting_sum = 0.0;
        uint resting_count = max(1u, count / 5);
        for (uint i = 0; i < resting_count; i++) {
            resting_sum += input[i];
        }
        float resting_hr = resting_sum / float(resting_count);
        
        // Calculate recovery heart rate (average of last 20% of data)
        float recovery_sum = 0.0;
        uint recovery_start = count - resting_count;
        for (uint i = recovery_start; i < count; i++) {
            recovery_sum += input[i];
        }
        float recovery_hr = recovery_sum / float(resting_count);
        
        // Calculate stress indicator (normalized deviation from resting)
        float stress_indicator = max(0.0, min(1.0, (avg_hr - resting_hr) / (max_hr - resting_hr + 1.0)));
        
        // Output results
        output[0] = avg_hr;           // Average heart rate
        output[1] = max_hr;           // Max heart rate
        output[2] = min_hr;           // Min heart rate
        output[3] = resting_hr;       // Resting heart rate
        output[4] = hrv;              // Heart rate variability
        output[5] = float(irregular_count); // Irregular rhythm count
        output[6] = recovery_hr;      // Recovery heart rate
        output[7] = stress_indicator; // Stress indicator
    }
}

// MARK: - HRV Calculation Kernel

kernel void calculateHRVMetrics(constant float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               constant uint& count [[buffer(2)]],
                               uint index [[thread_position_in_grid]]) {
    
    if (index >= count || index != 0) return; // Only use first thread
    
    if (count < 2) {
        // Not enough data for HRV calculation
        for (int i = 0; i < 6; i++) {
            output[i] = 0.0;
        }
        return;
    }
    
    // Calculate successive differences
    float sum_squared_diffs = 0.0;
    float sum_diffs = 0.0;
    uint pnn50_count = 0;
    
    for (uint i = 1; i < count; i++) {
        float diff = input[i] - input[i-1];
        sum_diffs += diff;
        sum_squared_diffs += diff * diff;
        
        // Count differences > 50ms for pNN50
        if (abs(diff) > 50.0) {
            pnn50_count++;
        }
    }
    
    uint diff_count = count - 1;
    
    // RMSSD: Root Mean Square of Successive Differences
    float rmssd = sqrt(sum_squared_diffs / float(diff_count));
    
    // Calculate mean and standard deviation for SDNN
    float sum = 0.0;
    for (uint i = 0; i < count; i++) {
        sum += input[i];
    }
    float mean = sum / float(count);
    
    float sum_squared_dev = 0.0;
    for (uint i = 0; i < count; i++) {
        float dev = input[i] - mean;
        sum_squared_dev += dev * dev;
    }
    
    // SDNN: Standard Deviation of NN intervals
    float sdnn = sqrt(sum_squared_dev / float(count));
    
    // pNN50: Percentage of successive RR intervals that differ by more than 50ms
    float pnn50 = (float(pnn50_count) / float(diff_count)) * 100.0;
    
    // Triangular Index approximation
    float triangular_index = sdnn / (1.0/128.0);
    
    // Stress Score: Higher RMSSD = lower stress
    float stress_score = max(0.0, min(100.0, (60.0 - rmssd) / 60.0 * 100.0));
    
    // Recovery Score: Higher RMSSD = better recovery
    float recovery_score = max(0.0, min(100.0, rmssd / 60.0 * 100.0));
    
    // Output results
    output[0] = rmssd;            // RMSSD
    output[1] = sdnn;             // SDNN
    output[2] = pnn50;            // pNN50
    output[3] = triangular_index; // Triangular Index
    output[4] = stress_score;     // Stress Score
    output[5] = recovery_score;   // Recovery Score
}

// MARK: - Sleep Metrics Processing Kernel

kernel void processSleepMetrics(constant float* input [[buffer(0)]],
                               device float* output [[buffer(1)]],
                               constant uint& count [[buffer(2)]],
                               uint index [[thread_position_in_grid]]) {
    
    if (index >= count || index != 0) return; // Only use first thread
    
    if (count == 0) {
        for (int i = 0; i < 10; i++) {
            output[i] = 0.0;
        }
        return;
    }
    
    // Input format: [hr1, movement1, timestamp1, hr2, movement2, timestamp2, ...]
    uint data_points = count / 3;
    
    float total_duration = 0.0;
    float deep_sleep_duration = 0.0;
    float rem_sleep_duration = 0.0;
    float light_sleep_duration = 0.0;
    float awake_duration = 0.0;
    
    float avg_movement = 0.0;
    float avg_heart_rate = 0.0;
    uint wake_count = 0;
    float sleep_latency = 0.0;
    
    // Calculate sleep metrics
    for (uint i = 0; i < data_points; i++) {
        uint base_idx = i * 3;
        float heart_rate = input[base_idx];
        float movement = input[base_idx + 1];
        float timestamp = input[base_idx + 2];
        
        avg_movement += movement;
        avg_heart_rate += heart_rate;
        
        // Sleep stage classification based on heart rate and movement
        if (movement > 0.8 || heart_rate > 80.0) {
            // Awake
            awake_duration += 1.0; // Assuming 1-minute intervals
            wake_count++;
        } else if (heart_rate < 55.0 && movement < 0.2) {
            // Deep sleep
            deep_sleep_duration += 1.0;
        } else if (heart_rate > 65.0 && movement < 0.4) {
            // REM sleep
            rem_sleep_duration += 1.0;
        } else {
            // Light sleep
            light_sleep_duration += 1.0;
        }
    }
    
    avg_movement /= float(data_points);
    avg_heart_rate /= float(data_points);
    
    // Convert minutes to seconds
    deep_sleep_duration *= 60.0;
    rem_sleep_duration *= 60.0;
    light_sleep_duration *= 60.0;
    awake_duration *= 60.0;
    
    total_duration = deep_sleep_duration + rem_sleep_duration + light_sleep_duration + awake_duration;
    
    // Calculate sleep efficiency (time asleep / time in bed)
    float sleep_efficiency = total_duration > 0 ? 
        (total_duration - awake_duration) / total_duration : 0.0;
    
    // Sleep quality based on movement and sleep stages
    float sleep_quality = max(0.0, min(1.0, 
        (deep_sleep_duration + rem_sleep_duration) / (total_duration + 1.0) * 
        (1.0 - avg_movement)));
    
    // Restfulness score
    float restfulness_score = max(0.0, min(1.0, 
        sleep_efficiency * (1.0 - avg_movement * 0.5)));
    
    // Sleep latency (time to fall asleep) - simplified calculation
    sleep_latency = 15.0 * 60.0; // Default 15 minutes
    
    // Output results
    output[0] = total_duration;      // Total sleep time
    output[1] = deep_sleep_duration; // Deep sleep time
    output[2] = rem_sleep_duration;  // REM sleep time
    output[3] = light_sleep_duration; // Light sleep time
    output[4] = awake_duration;      // Awake time
    output[5] = sleep_efficiency;    // Sleep efficiency
    output[6] = sleep_quality;       // Sleep quality
    output[7] = restfulness_score;   // Restfulness score
    output[8] = sleep_latency;       // Sleep latency
    output[9] = float(wake_count);   // Wake count
}

// MARK: - Health Correlation Analysis Kernel

kernel void calculateHealthCorrelations(constant float* input [[buffer(0)]],
                                       device float* output [[buffer(1)]],
                                       constant uint& matrix_size [[buffer(2)]],
                                       constant uint& data_length [[buffer(3)]],
                                       uint2 index [[thread_position_in_grid]]) {
    
    if (index.x >= matrix_size || index.y >= matrix_size) return;
    
    uint row = index.y;
    uint col = index.x;
    uint output_index = row * matrix_size + col;
    
    // Self-correlation is always 1.0
    if (row == col) {
        output[output_index] = 1.0;
        return;
    }
    
    // Calculate Pearson correlation coefficient
    float sum_x = 0.0, sum_y = 0.0;
    float sum_xy = 0.0, sum_x2 = 0.0, sum_y2 = 0.0;
    
    // Get data for dataset row and col
    uint x_offset = row * data_length;
    uint y_offset = col * data_length;
    
    for (uint i = 0; i < data_length; i++) {
        float x = input[x_offset + i];
        float y = input[y_offset + i];
        
        sum_x += x;
        sum_y += y;
        sum_xy += x * y;
        sum_x2 += x * x;
        sum_y2 += y * y;
    }
    
    float n = float(data_length);
    float numerator = n * sum_xy - sum_x * sum_y;
    float denominator = sqrt((n * sum_x2 - sum_x * sum_x) * (n * sum_y2 - sum_y * sum_y));
    
    float correlation = (denominator != 0.0) ? numerator / denominator : 0.0;
    
    // Clamp correlation to valid range [-1, 1]
    correlation = max(-1.0, min(1.0, correlation));
    
    output[output_index] = correlation;
}

// MARK: - Real-time Health Monitoring Kernel

kernel void processRealTimeHealthData(constant float* heart_rate [[buffer(0)]],
                                     constant float* hrv [[buffer(1)]],
                                     constant float* activity [[buffer(2)]],
                                     device float* output [[buffer(3)]],
                                     constant uint& count [[buffer(4)]],
                                     uint index [[thread_position_in_grid]]) {
    
    if (index >= count || index != 0) return; // Only use first thread
    
    // Real-time analysis for health monitoring
    float current_hr = heart_rate[count - 1];
    float current_hrv = hrv[count - 1];
    float current_activity = activity[count - 1];
    
    // Calculate trending direction (last 5 data points)
    uint trend_window = min(5u, count);
    float hr_trend = 0.0;
    float hrv_trend = 0.0;
    float activity_trend = 0.0;
    
    if (trend_window > 1) {
        uint start_idx = count - trend_window;
        
        float hr_slope = (heart_rate[count - 1] - heart_rate[start_idx]) / float(trend_window - 1);
        float hrv_slope = (hrv[count - 1] - hrv[start_idx]) / float(trend_window - 1);
        float activity_slope = (activity[count - 1] - activity[start_idx]) / float(trend_window - 1);
        
        hr_trend = hr_slope;
        hrv_trend = hrv_slope;
        activity_trend = activity_slope;
    }
    
    // Calculate stress level based on HR and HRV
    float stress_level = max(0.0, min(1.0, (current_hr - 60.0) / 40.0 - current_hrv / 100.0));
    
    // Calculate recovery status
    float recovery_status = max(0.0, min(1.0, current_hrv / 60.0 - current_activity * 0.5));
    
    // Calculate alertness level
    float alertness = max(0.0, min(1.0, current_activity + current_hr / 100.0));
    
    // Health score composite
    float health_score = max(0.0, min(1.0, 
        recovery_status * 0.4 + 
        (1.0 - stress_level) * 0.4 + 
        alertness * 0.2));
    
    // Output real-time metrics
    output[0] = current_hr;       // Current heart rate
    output[1] = current_hrv;      // Current HRV
    output[2] = current_activity; // Current activity level
    output[3] = hr_trend;         // Heart rate trend
    output[4] = hrv_trend;        // HRV trend
    output[5] = activity_trend;   // Activity trend
    output[6] = stress_level;     // Stress level (0-1)
    output[7] = recovery_status;  // Recovery status (0-1)
    output[8] = alertness;        // Alertness level (0-1)
    output[9] = health_score;     // Overall health score (0-1)
}

// MARK: - Advanced Biometric Analysis Kernel

kernel void analyzeAdvancedBiometrics(constant float* input [[buffer(0)]],
                                     device float* output [[buffer(1)]],
                                     constant uint& feature_count [[buffer(2)]],
                                     constant uint& sample_count [[buffer(3)]],
                                     uint index [[thread_position_in_grid]]) {
    
    if (index >= sample_count || index != 0) return; // Only use first thread
    
    // Advanced biometric analysis using multiple features
    // Input format: [feature1_samples..., feature2_samples..., etc.]
    
    uint features_per_sample = feature_count;
    uint total_samples = sample_count;
    
    // Initialize output metrics
    for (uint i = 0; i < 8; i++) {
        output[i] = 0.0;
    }
    
    if (total_samples == 0 || features_per_sample == 0) return;
    
    // Calculate feature statistics
    float feature_means[16]; // Support up to 16 features
    float feature_stds[16];
    
    for (uint f = 0; f < min(features_per_sample, 16u); f++) {
        float sum = 0.0;
        float sum_squared = 0.0;
        
        for (uint s = 0; s < total_samples; s++) {
            float value = input[f * total_samples + s];
            sum += value;
            sum_squared += value * value;
        }
        
        feature_means[f] = sum / float(total_samples);
        float variance = (sum_squared / float(total_samples)) - (feature_means[f] * feature_means[f]);
        feature_stds[f] = sqrt(max(0.0, variance));
    }
    
    // Calculate complexity metrics
    float complexity_score = 0.0;
    float variability_score = 0.0;
    float coherence_score = 0.0;
    
    for (uint f = 0; f < min(features_per_sample, 16u); f++) {
        // Normalized standard deviation as complexity measure
        if (feature_means[f] != 0.0) {
            complexity_score += feature_stds[f] / abs(feature_means[f]);
        }
        
        // Variability score
        variability_score += feature_stds[f];
        
        // Coherence (inverse of variability for stable features)
        coherence_score += 1.0 / (1.0 + feature_stds[f]);
    }
    
    complexity_score /= float(features_per_sample);
    variability_score /= float(features_per_sample);
    coherence_score /= float(features_per_sample);
    
    // Calculate entropy approximation
    float entropy = 0.0;
    for (uint f = 0; f < min(features_per_sample, 16u); f++) {
        if (feature_stds[f] > 0.0) {
            entropy += log2(feature_stds[f] + 1.0);
        }
    }
    entropy /= float(features_per_sample);
    
    // Output advanced metrics
    output[0] = complexity_score;   // Biometric complexity
    output[1] = variability_score;  // Overall variability
    output[2] = coherence_score;    // Signal coherence
    output[3] = entropy;            // Information entropy
    output[4] = feature_means[0];   // Primary feature mean
    output[5] = feature_stds[0];    // Primary feature std
    output[6] = min(1.0, complexity_score); // Normalized complexity
    output[7] = min(1.0, coherence_score);  // Normalized coherence
}