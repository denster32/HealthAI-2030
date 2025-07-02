# HealthAI 2030 - M0 – POC Scaffolding Plan

This document outlines the high-level plan for setting up the core engineering scaffolding for the HealthAI 2030 M0 – POC milestone. The focus areas include Data Ingestion, Edge Processing, Secure Sync, Sleep-Stage Transformer, and On-Device Memory Layout. The goal is to demonstrate a minimal end-to-end flow for sleep data processing and initial ML inference on-device.

## 1. Data Ingestion
**Goal**: Enable ingestion of all mentioned sensor data (Heart rate, HRV, oxygen saturation, body temperature, movement) from Apple Watch.

**Steps**:
*   **1.1 Identify and Integrate HealthKit Data Types**:
    *   Review `HealthDataManager.swift` and `HealthModels.swift` to ensure all required HealthKit data types (HR, HRV, SpO2, temperature, movement) are supported.
    *   Implement or extend methods in `HealthDataManager.swift` to query and receive real-time or near real-time data streams for these metrics from HealthKit.
*   **1.2 Data Buffering and Initial Validation**:
    *   Establish in-memory buffers for incoming sensor data.
    *   Implement basic data validation (e.g., range checks, null value handling) to ensure data quality before further processing.

## 2. Edge Processing
**Goal**: Implement full feature extraction for sleep staging on-device.

**Steps**:
*   **2.1 Feature Extraction Module**:
    *   Create a new module or extend an existing one (e.g., within `ML/` or `Analytics/`) dedicated to feature extraction.
    *   Develop algorithms to derive relevant features from raw sensor data for sleep staging (e.g., statistical features from HR/HRV, movement patterns, SpO2 variability).
*   **2.2 Pre-processing Pipeline**:
    *   Define a clear pipeline for data pre-processing, including normalization, segmentation (e.g., into 30-second epochs for sleep staging), and artifact removal.
    *   Ensure the output format of the features is compatible with the input requirements of the Sleep-Stage Transformer model.

## 3. Secure Sync
**Goal**: Establish a basic federated learning pipeline.

**Steps**:
*   **3.1 Secure Data Aggregation (Local)**:
    *   Implement a mechanism to securely aggregate processed features or model updates locally on the device. This could involve secure enclaves or encrypted local storage.
    *   Review `CoreDataManager.swift` and `DataSyncTests.swift` for existing data persistence and synchronization patterns.
*   **3.2 Basic Federated Learning Stub**:
    *   Create a placeholder or stub for the federated learning client. This client will be responsible for:
        *   Receiving a global model.
        *   Performing local training/inference.
        *   Generating a local model update (e.g., gradients or updated weights).
        *   Securely transmitting this update (simulated for POC, or via a simple encrypted channel).
    *   Focus on the secure *transmission* aspect for the POC, even if the "learning" part is minimal.

## 4. Sleep-Stage Transformer
**Goal**: Integrate a pre-trained model with basic inference capabilities.

**Steps**:
*   **4.1 Model Integration**:
    *   Identify a suitable pre-trained Sleep-Stage Transformer model (e.g., a simplified Core ML model).
    *   Integrate the model into the `ML/` directory, potentially extending `MLModelManager.swift` to load and manage this specific model.
*   **4.2 On-Device Inference**:
    *   Implement the inference pipeline using Core ML.
    *   Ensure the feature extraction output from Step 2.2 can be directly fed into the model.
    *   Develop a mechanism to receive and interpret the model's output (sleep stage classification).
*   **4.3 Basic Model Testing**:
    *   Create unit tests (e.g., in `Tests/AudioEngineTests.swift` or a new `Tests/MLModelTests.swift`) to verify the model loads correctly and performs basic inference with dummy data.

## 5. On-Device Memory Layout
**Goal**: Optimize for minimal RAM usage for all data.

**Steps**:
*   **5.1 Data Structure Definition**:
    *   Define efficient data structures (e.g., `structs` with value types, fixed-size arrays) for raw sensor data, extracted features, and model inputs/outputs.
    *   Review `HealthModels.swift` and propose new or modified structures as needed.
*   **5.2 Memory Profiling Strategy**:
    *   Outline a strategy for memory profiling during development (e.g., using Xcode's Instruments).
    *   Identify potential areas for memory optimization, such as reducing data redundancy or using more compact data representations.
*   **5.3 Data Lifecycle Management**:
    *   Implement clear data lifecycle management, ensuring that temporary data (e.g., raw sensor buffers after feature extraction) is deallocated promptly to minimize peak memory usage.

## High-Level Data Flow Diagram

```mermaid
graph TD
    A[Apple Watch Sensors] --> B(Data Ingestion);
    B --> C{Raw Sensor Data};
    C --> D[Edge Processing];
    D --> E{Extracted Features};
    E --> F[Sleep-Stage Transformer];
    F --> G{Sleep Stage Predictions};
    G --> H[On-Device Memory Layout];
    H --> I[Secure Sync];
    I --> J(Federated Learning Server);

    subgraph On-Device Components
        B
        D
        F
        H
        I
    end