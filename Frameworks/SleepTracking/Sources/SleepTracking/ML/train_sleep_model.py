#!/usr/bin/env python3
"""
Sleep Stage Prediction Model Training Script
Uses Create ML to train a neural network for sleep stage classification
"""

import pandas as pd
import numpy as np
import create_ml as cm
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import json
import pickle
import os

def generate_synthetic_sleep_data(n_samples=10000):
    """
    Generate synthetic sleep data based on real sleep patterns
    This simulates the data we would get from medical sleep studies
    """
    np.random.seed(42)
    
    data = []
    
    for i in range(n_samples):
        # Generate realistic sleep patterns
        time_of_night = np.random.uniform(0, 8)  # 0-8 hours into sleep
        
        # Base values for different sleep stages
        if time_of_night < 1:  # Early sleep - likely light
            stage = np.random.choice([0, 1], p=[0.3, 0.7])  # awake, light
            heart_rate = np.random.normal(65, 8)
            hrv = np.random.normal(35, 10)
            movement = np.random.exponential(0.3)
            blood_oxygen = np.random.normal(96, 1.5)
            temperature = np.random.normal(36.8, 0.3)
            breathing_rate = np.random.normal(14, 2)
            
        elif time_of_night < 3:  # Deep sleep phase
            stage = np.random.choice([1, 2], p=[0.4, 0.6])  # light, deep
            heart_rate = np.random.normal(55, 6)
            hrv = np.random.normal(45, 8)
            movement = np.random.exponential(0.1)
            blood_oxygen = np.random.normal(97, 1)
            temperature = np.random.normal(36.5, 0.2)
            breathing_rate = np.random.normal(12, 1.5)
            
        elif time_of_night < 5:  # REM sleep phase
            stage = np.random.choice([1, 3], p=[0.3, 0.7])  # light, rem
            heart_rate = np.random.normal(60, 10)
            hrv = np.random.normal(40, 12)
            movement = np.random.exponential(0.2)
            blood_oxygen = np.random.normal(96.5, 1.2)
            temperature = np.random.normal(36.7, 0.4)
            breathing_rate = np.random.normal(16, 3)
            
        else:  # Later sleep cycles
            stage = np.random.choice([0, 1, 2, 3], p=[0.2, 0.4, 0.2, 0.2])
            heart_rate = np.random.normal(62, 9)
            hrv = np.random.normal(38, 11)
            movement = np.random.exponential(0.25)
            blood_oxygen = np.random.normal(96.8, 1.3)
            temperature = np.random.normal(36.6, 0.3)
            breathing_rate = np.random.normal(15, 2.5)
        
        # Add some noise and realistic variations
        heart_rate = max(40, min(100, heart_rate + np.random.normal(0, 3)))
        hrv = max(10, min(80, hrv + np.random.normal(0, 5)))
        movement = min(1.0, movement + np.random.normal(0, 0.1))
        blood_oxygen = max(90, min(100, blood_oxygen + np.random.normal(0, 0.5)))
        temperature = max(35.5, min(37.5, temperature + np.random.normal(0, 0.1)))
        breathing_rate = max(8, min(25, breathing_rate + np.random.normal(0, 1)))
        
        # Previous stage (simulate sleep cycle transitions)
        previous_stage = (stage - 1) % 4 if np.random.random() > 0.3 else stage
        
        data.append({
            'heartRate': heart_rate,
            'hrv': hrv,
            'movement': movement,
            'bloodOxygen': blood_oxygen,
            'temperature': temperature,
            'breathingRate': breathing_rate,
            'timeOfNight': time_of_night,
            'previousStage': previous_stage,
            'stage': stage
        })
    
    return pd.DataFrame(data)

def create_ml_training_data(df):
    """Prepare data for Create ML training with feature scaling."""
    feature_columns = [
        'heartRate', 'hrv', 'movement', 'bloodOxygen',
        'temperature', 'breathingRate', 'timeOfNight', 'previousStage'
    ]

    target_column = 'stage'

    X = df[feature_columns]
    y = df[target_column]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    train_df = pd.DataFrame(X_train_scaled, columns=feature_columns)
    train_df['stage'] = y_train.reset_index(drop=True)

    test_df = pd.DataFrame(X_test_scaled, columns=feature_columns)
    test_df['stage'] = y_test.reset_index(drop=True)

    return train_df, test_df, scaler

def train_core_ml_model(train_data, test_data, output_path):
    """
    Train the Core ML model using Create ML
    """
    print("🤖 Training Core ML Sleep Stage Prediction Model...")
    
    # Configure the model
    model_config = {
        "algorithm": "neuralNetwork",
        "parameters": {
            "layers": [
                {"type": "innerProduct", "outputSize": 64, "activation": "relu"},
                {"type": "innerProduct", "outputSize": 32, "activation": "relu"},
                {"type": "innerProduct", "outputSize": 4, "activation": "softmax"}
            ],
            "learningRate": 0.001,
            "epochs": 100,
            "batchSize": 32
        }
    }
    
    # Train the model
    model = cm.neural_network_classifier(
        training_data=train_data,
        target_column='stage',
        features=['heartRate', 'hrv', 'movement', 'bloodOxygen', 
                 'temperature', 'breathingRate', 'timeOfNight', 'previousStage'],
        validation_data=test_data,
        parameters=model_config
    )
    
    # Evaluate the model
    evaluation = model.evaluation_metrics
    print(f"📊 Model Accuracy: {evaluation['accuracy']:.3f}")
    print(f"📊 Precision: {evaluation['precision']:.3f}")
    print(f"📊 Recall: {evaluation['recall']:.3f}")
    
    # Save the model
    model.save(output_path)
    print(f"✅ Model saved to: {output_path}")
    
    return model, evaluation

def create_model_metadata(evaluation_metrics):
    """
    Create metadata for the trained model
    """
    metadata = {
        "model_info": {
            "name": "SleepStagePredictor",
            "version": "1.0",
            "description": "Neural network for sleep stage prediction using biometric data",
            "author": "SomnaSync Pro",
            "license": "MIT",
            "creation_date": "2024-01-15"
        },
        "training_info": {
            "algorithm": "Neural Network",
            "architecture": "64-32-4 (ReLU activation)",
            "training_samples": 8000,
            "validation_samples": 2000,
            "epochs": 100,
            "batch_size": 32,
            "learning_rate": 0.001
        },
        "performance_metrics": {
            "accuracy": evaluation_metrics['accuracy'],
            "precision": evaluation_metrics['precision'],
            "recall": evaluation_metrics['recall'],
            "f1_score": evaluation_metrics.get('f1', 0.0)
        },
        "features": {
            "input_features": [
                "heartRate", "hrv", "movement", "bloodOxygen",
                "temperature", "breathingRate", "timeOfNight", "previousStage"
            ],
            "output_classes": ["awake", "light", "deep", "rem"],
            "feature_descriptions": {
                "heartRate": "Heart rate in BPM",
                "hrv": "Heart rate variability in ms",
                "movement": "Movement intensity (0-1)",
                "bloodOxygen": "Blood oxygen saturation %",
                "temperature": "Body temperature in Celsius",
                "breathingRate": "Breathing rate per minute",
                "timeOfNight": "Time since sleep start in hours",
                "previousStage": "Previous sleep stage (0-3)"
            }
        }
    }
    
    return metadata

def main():
    """
    Main training pipeline
    """
    print("🚀 Starting Sleep Stage Prediction Model Training...")
    
    # Create output directory
    output_dir = "SomnaSync/ML"
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate training data
    print("📊 Generating synthetic sleep data...")
    sleep_data = generate_synthetic_sleep_data(n_samples=10000)
    
    # Prepare data for training
    print("🔧 Preparing training data...")
    train_data, test_data, scaler = create_ml_training_data(sleep_data)
    
    # Train the model
    model_path = os.path.join(output_dir, "SleepStagePredictor.mlmodel")
    model, evaluation = train_core_ml_model(train_data, test_data, model_path)
    
    # Create and save metadata
    metadata = create_model_metadata(evaluation)
    metadata_path = os.path.join(output_dir, "model_metadata.json")
    
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    # Save the scaler for preprocessing new data
    scaler_path = os.path.join(output_dir, "feature_scaler.pkl")
    with open(scaler_path, 'wb') as f:
        pickle.dump(scaler, f)

    print(f"📋 Model metadata saved to: {metadata_path}")
    print(f"📋 Feature scaler saved to: {scaler_path}")
    
    # Print summary
    print("\n🎉 Training Complete!")
    print(f"📁 Model: {model_path}")
    print(f"📁 Metadata: {metadata_path}")
    print(f"📊 Accuracy: {evaluation['accuracy']:.3f}")
    
    return model, evaluation, scaler

if __name__ == "__main__":
    main()
