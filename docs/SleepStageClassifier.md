# Sleep Stage Classification Model

## Model Overview

- **Name:** SleepStageClassifier
- **Type:** Classification (RandomForest → CoreML)
- **Purpose:** Predicts the user's current sleep stage based on physiological signals.

## Inputs

| Feature       | Type    | Description                     |
| ------------- | ------- | ------------------------------- |
| heart_rate    | Double  | Current heart rate (beats/min)  |
| hrv           | Double  | Heart rate variability (ms)     |
| motion        | Double  | Motion intensity (0.0–1.0)      |
| spo2          | Double  | Blood oxygen saturation (%)     |

## Output

| Name         | Type   | Description                                          |
| ------------ | ------ | ---------------------------------------------------- |
| sleep_stage  | Int64  | Predicted sleep stage index                         |

### Sleep Stage Indices

- 0: Awake
- 1: Light Sleep
- 2: Deep Sleep
- 3: REM Sleep

## Performance Metrics (Simulated Data)

| Metric             | Value       |
| ------------------ | ----------- |
| Accuracy           | ~0.85       |
| Precision (avg.)   | ~0.84       |
| Recall (avg.)      | ~0.85       |
| F1 Score (avg.)    | ~0.85       |

## Integration

1. Add `SleepStageClassifier.mlmodel` to your Xcode project under the `ml` folder.
2. Xcode auto-generates a Swift wrapper class `SleepStageClassifier`.
3. Load the model:

   ```swift
   let config = MLModelConfiguration()
   let model = try SleepStageClassifier(configuration: config)
   ```

4. Prepare input:

   ```swift
   let input = SleepStageClassifierInput(
       heart_rate: 65.0,
       hrv: 50.0,
       motion: 0.1,
       spo2: 97.0
   )
   ```

5. Perform prediction:

   ```swift
   let output = try model.prediction(input: input)
   let stageIndex = output.sleep_stage
   ```

6. Map index to `SleepStageType`:

   ```swift
   switch stageIndex {
   case 0: return .awake
   case 1: return .lightSleep
   case 2: return .deepSleep
   case 3: return .remSleep
   default: return .unknown
   }
   ```

## Retraining & Validation

- Use the Jupyter notebook `ml/SleepStageClassification.ipynb` to regenerate the model:

   ```bash
   pip install -r ml/requirements.txt
   jupyter notebook ml/SleepStageClassification.ipynb
   ```

## References

- [SleepStageClassification Notebook](ml/SleepStageClassification.ipynb)
- [CoreML Documentation](https://developer.apple.com/documentation/coreml)
