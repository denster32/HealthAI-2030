#!/bin/bash

# HealthAI 2030 Sample Data Generator
# This script generates sample health data for development and testing purposes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SAMPLE_DATA_DIR="$PROJECT_ROOT/SampleData"
PYTHON_SCRIPT="$SCRIPT_DIR/generate_health_data.py"

echo -e "${BLUE}🏥 HealthAI 2030 Sample Data Generator${NC}"
echo "=========================================="

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is required but not installed.${NC}"
    echo "Please install Python 3 and try again."
    exit 1
fi

# Check if required Python packages are installed
echo -e "${YELLOW}📦 Checking Python dependencies...${NC}"
python3 -c "import pandas, numpy, datetime" 2>/dev/null || {
    echo -e "${YELLOW}📦 Installing required Python packages...${NC}"
    pip3 install pandas numpy
}

# Create sample data directory
echo -e "${YELLOW}📁 Creating sample data directory...${NC}"
mkdir -p "$SAMPLE_DATA_DIR"

# Generate sample data
echo -e "${YELLOW}🔧 Generating sample health data...${NC}"

cat > "$PYTHON_SCRIPT" << 'EOF'
#!/usr/bin/env python3
"""
HealthAI 2030 Sample Data Generator
Generates realistic sample health data for development and testing
"""

import pandas as pd
import numpy as np
import json
import random
from datetime import datetime, timedelta
import os

def generate_heart_rate_data(days=30):
    """Generate realistic heart rate data"""
    print("Generating heart rate data...")
    
    # Base heart rate varies by time of day and activity
    base_hr = 72
    data = []
    
    start_date = datetime.now() - timedelta(days=days)
    
    for day in range(days):
        current_date = start_date + timedelta(days=day)
        
        # Generate 24 hours of data (every 5 minutes)
        for hour in range(24):
            for minute in range(0, 60, 5):
                timestamp = current_date + timedelta(hours=hour, minutes=minute)
                
                # Heart rate varies by time of day
                if 6 <= hour <= 8:  # Morning
                    hr = base_hr + random.randint(-5, 15)
                elif 12 <= hour <= 14:  # Afternoon
                    hr = base_hr + random.randint(-3, 10)
                elif 18 <= hour <= 20:  # Evening
                    hr = base_hr + random.randint(-2, 8)
                elif 22 <= hour or hour <= 4:  # Night
                    hr = base_hr + random.randint(-10, 5)
                else:
                    hr = base_hr + random.randint(-5, 10)
                
                # Add some variability
                hr += random.randint(-3, 3)
                hr = max(40, min(120, hr))  # Keep within realistic bounds
                
                data.append({
                    "timestamp": timestamp.isoformat(),
                    "value": hr,
                    "unit": "bpm",
                    "type": "heartRate",
                    "source": "Apple Watch"
                })
    
    return data

def generate_sleep_data(days=30):
    """Generate realistic sleep data"""
    print("Generating sleep data...")
    
    data = []
    start_date = datetime.now() - timedelta(days=days)
    
    for day in range(days):
        current_date = start_date + timedelta(days=day)
        
        # Sleep patterns vary by day of week
        if current_date.weekday() < 5:  # Weekday
            sleep_start = current_date.replace(hour=23, minute=random.randint(0, 30))
            sleep_duration = random.randint(6, 8)  # 6-8 hours
        else:  # Weekend
            sleep_start = current_date.replace(hour=random.randint(22, 24), minute=random.randint(0, 59))
            sleep_duration = random.randint(7, 10)  # 7-10 hours
        
        sleep_end = sleep_start + timedelta(hours=sleep_duration)
        
        # Sleep stages
        deep_sleep = sleep_duration * random.uniform(0.15, 0.25)  # 15-25%
        rem_sleep = sleep_duration * random.uniform(0.20, 0.30)   # 20-30%
        light_sleep = sleep_duration - deep_sleep - rem_sleep
        
        data.append({
            "date": current_date.strftime("%Y-%m-%d"),
            "sleepStart": sleep_start.isoformat(),
            "sleepEnd": sleep_end.isoformat(),
            "totalDuration": sleep_duration,
            "deepSleep": round(deep_sleep, 2),
            "remSleep": round(rem_sleep, 2),
            "lightSleep": round(light_sleep, 2),
            "sleepQuality": random.randint(60, 95),
            "source": "Apple Watch"
        })
    
    return data

def generate_activity_data(days=30):
    """Generate realistic activity data"""
    print("Generating activity data...")
    
    data = []
    start_date = datetime.now() - timedelta(days=days)
    
    for day in range(days):
        current_date = start_date + timedelta(days=day)
        
        # Activity varies by day of week
        if current_date.weekday() < 5:  # Weekday
            steps = random.randint(6000, 12000)
            activeMinutes = random.randint(20, 45)
        else:  # Weekend
            steps = random.randint(4000, 15000)
            activeMinutes = random.randint(15, 60)
        
        # Calculate calories (rough estimate)
        calories = steps * 0.04 + activeMinutes * 5
        
        data.append({
            "date": current_date.strftime("%Y-%m-%d"),
            "steps": steps,
            "activeMinutes": activeMinutes,
            "calories": round(calories),
            "distance": round(steps * 0.0008, 2),  # Rough km conversion
            "flightsClimbed": random.randint(0, 20),
            "source": "iPhone"
        })
    
    return data

def generate_weight_data(days=30):
    """Generate realistic weight data"""
    print("Generating weight data...")
    
    data = []
    start_date = datetime.now() - timedelta(days=days)
    
    # Start with a base weight
    base_weight = 70.0  # kg
    
    for day in range(days):
        current_date = start_date + timedelta(days=day)
        
        # Weight fluctuates daily
        weight_change = random.uniform(-0.5, 0.3)
        base_weight += weight_change
        
        # Keep weight within realistic bounds
        base_weight = max(50.0, min(120.0, base_weight))
        
        data.append({
            "date": current_date.strftime("%Y-%m-%d"),
            "weight": round(base_weight, 1),
            "unit": "kg",
            "bodyFatPercentage": round(random.uniform(15, 25), 1),
            "bmi": round(base_weight / (1.75 * 1.75), 1),  # Assuming 1.75m height
            "source": "Smart Scale"
        })
    
    return data

def generate_blood_pressure_data(days=30):
    """Generate realistic blood pressure data"""
    print("Generating blood pressure data...")
    
    data = []
    start_date = datetime.now() - timedelta(days=days)
    
    for day in range(days):
        current_date = start_date + timedelta(days=day)
        
        # Generate 1-3 readings per day
        readings = random.randint(1, 3)
        
        for _ in range(readings):
            # Systolic: 90-140 mmHg
            systolic = random.randint(90, 140)
            # Diastolic: 60-90 mmHg
            diastolic = random.randint(60, 90)
            
            # Ensure diastolic is always lower than systolic
            if diastolic >= systolic:
                diastolic = systolic - random.randint(10, 30)
                diastolic = max(60, diastolic)
            
            timestamp = current_date + timedelta(hours=random.randint(8, 20))
            
            data.append({
                "timestamp": timestamp.isoformat(),
                "systolic": systolic,
                "diastolic": diastolic,
                "unit": "mmHg",
                "source": "Blood Pressure Monitor"
            })
    
    return data

def generate_medication_data(days=30):
    """Generate sample medication data"""
    print("Generating medication data...")
    
    medications = [
        {"name": "Aspirin", "dosage": "81mg", "frequency": "daily", "time": "08:00"},
        {"name": "Vitamin D", "dosage": "1000IU", "frequency": "daily", "time": "08:00"},
        {"name": "Omega-3", "dosage": "1000mg", "frequency": "daily", "time": "12:00"},
        {"name": "Magnesium", "dosage": "400mg", "frequency": "daily", "time": "20:00"}
    ]
    
    data = []
    start_date = datetime.now() - timedelta(days=days)
    
    for day in range(days):
        current_date = start_date + timedelta(days=day)
        
        for med in medications:
            # 90% adherence rate
            if random.random() < 0.9:
                time_parts = med["time"].split(":")
                timestamp = current_date.replace(
                    hour=int(time_parts[0]), 
                    minute=int(time_parts[1])
                )
                
                data.append({
                    "timestamp": timestamp.isoformat(),
                    "medication": med["name"],
                    "dosage": med["dosage"],
                    "taken": True,
                    "source": "Manual Entry"
                })
    
    return data

def main():
    """Generate all sample data"""
    print("🏥 Generating HealthAI 2030 Sample Data")
    print("=" * 50)
    
    # Create output directory
    output_dir = os.path.join(os.path.dirname(__file__), "..", "SampleData")
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate different types of data
    data_types = {
        "heart_rate": generate_heart_rate_data(),
        "sleep": generate_sleep_data(),
        "activity": generate_activity_data(),
        "weight": generate_weight_data(),
        "blood_pressure": generate_blood_pressure_data(),
        "medications": generate_medication_data()
    }
    
    # Save data to JSON files
    for data_type, data in data_types.items():
        filename = os.path.join(output_dir, f"{data_type}_sample_data.json")
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"✅ Saved {len(data)} {data_type} records to {filename}")
    
    # Create a summary file
    summary = {
        "generated_at": datetime.now().isoformat(),
        "data_types": {k: len(v) for k, v in data_types.items()},
        "date_range": {
            "start": (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d"),
            "end": datetime.now().strftime("%Y-%m-%d")
        }
    }
    
    summary_file = os.path.join(output_dir, "sample_data_summary.json")
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    
    print(f"\n✅ Sample data generation complete!")
    print(f"📁 Data saved to: {output_dir}")
    print(f"📊 Summary: {summary_file}")
    
    # Print summary
    print("\n📈 Generated Data Summary:")
    for data_type, count in summary["data_types"].items():
        print(f"   • {data_type}: {count} records")

if __name__ == "__main__":
    main()
EOF

# Make the Python script executable
chmod +x "$PYTHON_SCRIPT"

# Run the data generator
echo -e "${YELLOW}🚀 Running sample data generator...${NC}"
python3 "$PYTHON_SCRIPT"

# Create a README for the sample data
cat > "$SAMPLE_DATA_DIR/README.md" << 'EOF'
# Sample Data for HealthAI 2030

This directory contains sample health data generated for development and testing purposes.

## Data Files

- `heart_rate_sample_data.json` - Heart rate measurements (every 5 minutes for 30 days)
- `sleep_sample_data.json` - Sleep tracking data (daily for 30 days)
- `activity_sample_data.json` - Activity data including steps, calories, distance
- `weight_sample_data.json` - Weight and body composition data
- `blood_pressure_sample_data.json` - Blood pressure readings
- `medications_sample_data.json` - Medication tracking data
- `sample_data_summary.json` - Summary of all generated data

## Usage

### Loading Sample Data in Development

```swift
// Load heart rate data
if let url = Bundle.main.url(forResource: "heart_rate_sample_data", withExtension: "json"),
   let data = try? Data(contentsOf: url) {
    let heartRateData = try JSONDecoder().decode([HeartRateData].self, from: data)
    // Use the data for testing
}
```

### Importing to HealthKit (Development Only)

```swift
// Import sample data to HealthKit for testing
func importSampleData() async throws {
    let healthStore = HKHealthStore()
    
    // Request permissions
    let typesToShare: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .stepCount)!
    ]
    
    try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToShare)
    
    // Import sample data
    // Implementation depends on your data structure
}
```

## Data Characteristics

### Heart Rate Data
- **Frequency**: Every 5 minutes
- **Range**: 40-120 BPM
- **Patterns**: Varies by time of day (lower at night, higher during activity)
- **Source**: Apple Watch simulation

### Sleep Data
- **Frequency**: Daily
- **Duration**: 6-10 hours (varies by weekday/weekend)
- **Stages**: Deep, REM, and light sleep
- **Quality**: 60-95 score
- **Source**: Apple Watch simulation

### Activity Data
- **Frequency**: Daily
- **Steps**: 4,000-15,000 (varies by weekday/weekend)
- **Active Minutes**: 15-60 minutes
- **Calories**: Calculated from steps and activity
- **Source**: iPhone simulation

### Weight Data
- **Frequency**: Daily
- **Range**: 50-120 kg
- **Variability**: ±0.5 kg daily fluctuations
- **Additional**: Body fat percentage and BMI
- **Source**: Smart scale simulation

### Blood Pressure Data
- **Frequency**: 1-3 readings per day
- **Systolic**: 90-140 mmHg
- **Diastolic**: 60-90 mmHg
- **Source**: Blood pressure monitor simulation

### Medication Data
- **Medications**: Common supplements and medications
- **Adherence**: 90% compliance rate
- **Frequency**: Daily at specific times
- **Source**: Manual entry simulation

## Regenerating Data

To regenerate the sample data with different parameters:

```bash
# From the project root
./Scripts/generate_sample_data.sh

# Or run the Python script directly
python3 Scripts/generate_health_data.py
```

## Notes

- This data is for development and testing purposes only
- Data is realistic but not based on real health records
- Patterns simulate typical health data variations
- Use this data to test features without requiring real health data
- Do not use this data for production or medical purposes

## Privacy

- All data is synthetic and contains no real health information
- No personal identifiers are included
- Data follows realistic patterns but is completely fictional
- Safe to use in development environments
EOF

# Create a Swift helper for loading sample data
cat > "$SAMPLE_DATA_DIR/SampleDataLoader.swift" << 'EOF'
import Foundation
import HealthKit

/// Helper class for loading and managing sample data in development
@available(iOS 15.0, *)
public class SampleDataLoader {
    
    // MARK: - Singleton
    public static let shared = SampleDataLoader()
    
    private init() {}
    
    // MARK: - Data Loading
    
    /// Load sample heart rate data
    public func loadHeartRateData() -> [HeartRateSample] {
        guard let data = loadJSONData(filename: "heart_rate_sample_data") else {
            return []
        }
        
        do {
            let samples = try JSONDecoder().decode([HeartRateSample].self, from: data)
            return samples
        } catch {
            print("Failed to decode heart rate data: \(error)")
            return []
        }
    }
    
    /// Load sample sleep data
    public func loadSleepData() -> [SleepSample] {
        guard let data = loadJSONData(filename: "sleep_sample_data") else {
            return []
        }
        
        do {
            let samples = try JSONDecoder().decode([SleepSample].self, from: data)
            return samples
        } catch {
            print("Failed to decode sleep data: \(error)")
            return []
        }
    }
    
    /// Load sample activity data
    public func loadActivityData() -> [ActivitySample] {
        guard let data = loadJSONData(filename: "activity_sample_data") else {
            return []
        }
        
        do {
            let samples = try JSONDecoder().decode([ActivitySample].self, from: data)
            return samples
        } catch {
            print("Failed to decode activity data: \(error)")
            return []
        }
    }
    
    /// Load sample weight data
    public func loadWeightData() -> [WeightSample] {
        guard let data = loadJSONData(filename: "weight_sample_data") else {
            return []
        }
        
        do {
            let samples = try JSONDecoder().decode([WeightSample].self, from: data)
            return samples
        } catch {
            print("Failed to decode weight data: \(error)")
            return []
        }
    }
    
    /// Load sample blood pressure data
    public func loadBloodPressureData() -> [BloodPressureSample] {
        guard let data = loadJSONData(filename: "blood_pressure_sample_data") else {
            return []
        }
        
        do {
            let samples = try JSONDecoder().decode([BloodPressureSample].self, from: data)
            return samples
        } catch {
            print("Failed to decode blood pressure data: \(error)")
            return []
        }
    }
    
    /// Load sample medication data
    public func loadMedicationData() -> [MedicationSample] {
        guard let data = loadJSONData(filename: "medications_sample_data") else {
            return []
        }
        
        do {
            let samples = try JSONDecoder().decode([MedicationSample].self, from: data)
            return samples
        } catch {
            print("Failed to decode medication data: \(error)")
            return []
        }
    }
    
    // MARK: - HealthKit Import (Development Only)
    
    /// Import sample heart rate data to HealthKit
    public func importHeartRateToHealthKit() async throws {
        let healthStore = HKHealthStore()
        
        // Request permissions
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        try await healthStore.requestAuthorization(toShare: [heartRateType], read: [heartRateType])
        
        // Load sample data
        let samples = loadHeartRateData()
        
        // Convert to HealthKit samples
        let healthKitSamples = samples.compactMap { sample -> HKQuantitySample? in
            guard let date = ISO8601DateFormatter().date(from: sample.timestamp) else {
                return nil
            }
            
            let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: sample.value)
            return HKQuantitySample(
                type: heartRateType,
                quantity: quantity,
                start: date,
                end: date,
                device: HKDevice(name: sample.source, manufacturer: "HealthAI", model: "Sample", hardwareVersion: "1.0", firmwareVersion: "1.0", softwareVersion: "1.0", localIdentifier: nil, udiDeviceIdentifier: nil),
                metadata: nil
            )
        }
        
        // Save to HealthKit
        try await healthStore.save(healthKitSamples)
        print("Imported \(healthKitSamples.count) heart rate samples to HealthKit")
    }
    
    // MARK: - Private Helpers
    
    private func loadJSONData(filename: String) -> Data? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Could not find \(filename).json in bundle")
            return nil
        }
        
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Failed to load \(filename).json: \(error)")
            return nil
        }
    }
}

// MARK: - Sample Data Models

public struct HeartRateSample: Codable {
    public let timestamp: String
    public let value: Double
    public let unit: String
    public let type: String
    public let source: String
}

public struct SleepSample: Codable {
    public let date: String
    public let sleepStart: String
    public let sleepEnd: String
    public let totalDuration: Double
    public let deepSleep: Double
    public let remSleep: Double
    public let lightSleep: Double
    public let sleepQuality: Int
    public let source: String
}

public struct ActivitySample: Codable {
    public let date: String
    public let steps: Int
    public let activeMinutes: Int
    public let calories: Int
    public let distance: Double
    public let flightsClimbed: Int
    public let source: String
}

public struct WeightSample: Codable {
    public let date: String
    public let weight: Double
    public let unit: String
    public let bodyFatPercentage: Double
    public let bmi: Double
    public let source: String
}

public struct BloodPressureSample: Codable {
    public let timestamp: String
    public let systolic: Int
    public let diastolic: Int
    public let unit: String
    public let source: String
}

public struct MedicationSample: Codable {
    public let timestamp: String
    public let medication: String
    public let dosage: String
    public let taken: Bool
    public let source: String
}
EOF

echo -e "${GREEN}✅ Sample data generation complete!${NC}"
echo ""
echo -e "${BLUE}📁 Sample data location:${NC} $SAMPLE_DATA_DIR"
echo -e "${BLUE}📖 Documentation:${NC} $SAMPLE_DATA_DIR/README.md"
echo -e "${BLUE}🔧 Swift Helper:${NC} $SAMPLE_DATA_DIR/SampleDataLoader.swift"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. Copy the sample data files to your app bundle for testing"
echo "2. Use SampleDataLoader.swift to load data in your app"
echo "3. Import sample data to HealthKit for realistic testing"
echo ""
echo -e "${GREEN}🎉 You're ready to start developing with realistic health data!${NC}" 