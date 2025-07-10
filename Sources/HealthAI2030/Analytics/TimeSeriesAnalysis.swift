import Foundation
import Combine

/// Advanced time series analysis engine for healthcare temporal data
public class TimeSeriesAnalysis {
    
    // MARK: - Properties
    private let analyticsEngine: AdvancedAnalyticsEngine
    private let configManager: AnalyticsConfiguration
    private let errorHandler: AnalyticsErrorHandling
    private let performanceMonitor: AnalyticsPerformanceMonitor
    
    // MARK: - Time Series Models
    public enum TimeSeriesModel {
        case autoregressive(order: Int)
        case movingAverage(order: Int)
        case arima(p: Int, d: Int, q: Int)
        case exponentialSmoothing
        case seasonalDecomposition
        case prophet
    }
    
    // MARK: - Data Structures
    public struct TimeSeriesData {
        let timestamps: [Date]
        let values: [Double]
        let metadata: [String: Any]
    }
    
    public struct ForecastResult {
        let predictions: [Double]
        let confidenceIntervals: [(lower: Double, upper: Double)]
        let timestamps: [Date]
        let model: TimeSeriesModel
        let accuracy: Double
        let residuals: [Double]
    }
    
    public struct SeasonalDecomposition {
        let trend: [Double]
        let seasonal: [Double]
        let residual: [Double]
        let seasonalPeriod: Int
        let strength: Double
    }
    
    public struct AnomalyDetection {
        let anomalies: [Int] // Indices of anomalous points
        let scores: [Double] // Anomaly scores
        let threshold: Double
        let method: String
    }
    
    public struct TrendAnalysis {
        let slope: Double
        let pValue: Double
        let confidence: Double
        let trendDirection: TrendDirection
        let changePoints: [Int]
    }
    
    public enum TrendDirection {
        case increasing
        case decreasing
        case stable
        case volatile
    }
    
    // MARK: - Initialization
    public init(analyticsEngine: AdvancedAnalyticsEngine,
                configManager: AnalyticsConfiguration,
                errorHandler: AnalyticsErrorHandling,
                performanceMonitor: AnalyticsPerformanceMonitor) {
        self.analyticsEngine = analyticsEngine
        self.configManager = configManager
        self.errorHandler = errorHandler
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Public Methods
    
    /// Perform time series forecasting
    public func forecastTimeSeries(
        data: TimeSeriesData,
        model: TimeSeriesModel,
        forecastHorizon: Int,
        confidenceLevel: Double = 0.95
    ) async throws -> ForecastResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("time_series_forecasting", value: executionTime)
        }
        
        do {
            guard data.values.count >= 10 else {
                throw AnalyticsError.insufficientData("Need at least 10 data points for forecasting")
            }
            
            guard forecastHorizon > 0 && forecastHorizon <= 100 else {
                throw AnalyticsError.invalidInput("Forecast horizon must be between 1 and 100")
            }
            
            let predictions: [Double]
            let residuals: [Double]
            let accuracy: Double
            
            switch model {
            case .autoregressive(let order):
                (predictions, residuals, accuracy) = try await performARForecasting(
                    data: data.values,
                    order: order,
                    horizon: forecastHorizon
                )
                
            case .movingAverage(let order):
                (predictions, residuals, accuracy) = try await performMAForecasting(
                    data: data.values,
                    order: order,
                    horizon: forecastHorizon
                )
                
            case .arima(let p, let d, let q):
                (predictions, residuals, accuracy) = try await performARIMAForecasting(
                    data: data.values,
                    p: p, d: d, q: q,
                    horizon: forecastHorizon
                )
                
            case .exponentialSmoothing:
                (predictions, residuals, accuracy) = try await performExponentialSmoothing(
                    data: data.values,
                    horizon: forecastHorizon
                )
                
            case .seasonalDecomposition:
                (predictions, residuals, accuracy) = try await performSeasonalForecasting(
                    data: data.values,
                    horizon: forecastHorizon
                )
                
            case .prophet:
                (predictions, residuals, accuracy) = try await performProphetForecasting(
                    data: data,
                    horizon: forecastHorizon
                )
            }
            
            // Calculate confidence intervals
            let confidenceIntervals = calculateConfidenceIntervals(
                predictions: predictions,
                residuals: residuals,
                confidenceLevel: confidenceLevel
            )
            
            // Generate future timestamps
            let futureTimestamps = generateFutureTimestamps(
                lastTimestamp: data.timestamps.last ?? Date(),
                count: forecastHorizon
            )
            
            return ForecastResult(
                predictions: predictions,
                confidenceIntervals: confidenceIntervals,
                timestamps: futureTimestamps,
                model: model,
                accuracy: accuracy,
                residuals: residuals
            )
            
        } catch {
            await errorHandler.handleError(error, context: "TimeSeriesAnalysis.forecastTimeSeries")
            throw error
        }
    }
    
    /// Perform seasonal decomposition
    public func performSeasonalDecomposition(
        data: TimeSeriesData,
        seasonalPeriod: Int? = nil
    ) async throws -> SeasonalDecomposition {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("seasonal_decomposition", value: executionTime)
        }
        
        do {
            guard data.values.count >= 24 else {
                throw AnalyticsError.insufficientData("Need at least 24 data points for seasonal decomposition")
            }
            
            let period = seasonalPeriod ?? detectSeasonalPeriod(data.values)
            
            // Extract trend using moving average
            let trend = extractTrend(data.values, period: period)
            
            // Detrend the data
            let detrended = zip(data.values, trend).map { $0 - $1 }
            
            // Extract seasonal component
            let seasonal = extractSeasonal(detrended, period: period)
            
            // Calculate residuals
            let residual = zip3(data.values, trend, seasonal).map { value, t, s in
                value - t - s
            }
            
            // Calculate seasonal strength
            let seasonalStrength = calculateSeasonalStrength(seasonal: seasonal, residual: residual)
            
            return SeasonalDecomposition(
                trend: trend,
                seasonal: seasonal,
                residual: residual,
                seasonalPeriod: period,
                strength: seasonalStrength
            )
            
        } catch {
            await errorHandler.handleError(error, context: "TimeSeriesAnalysis.performSeasonalDecomposition")
            throw error
        }
    }
    
    /// Detect anomalies in time series data
    public func detectAnomalies(
        data: TimeSeriesData,
        method: String = "isolation_forest",
        threshold: Double = 2.0
    ) async throws -> AnomalyDetection {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("anomaly_detection", value: executionTime)
        }
        
        do {
            let scores: [Double]
            
            switch method.lowercased() {
            case "zscore":
                scores = calculateZScores(data.values)
            case "iqr":
                scores = calculateIQRScores(data.values)
            case "isolation_forest":
                scores = calculateIsolationForestScores(data.values)
            case "statistical":
                scores = calculateStatisticalAnomalyScores(data.values)
            default:
                scores = calculateZScores(data.values)
            }
            
            let anomalies = scores.enumerated().compactMap { index, score in
                abs(score) > threshold ? index : nil
            }
            
            return AnomalyDetection(
                anomalies: anomalies,
                scores: scores,
                threshold: threshold,
                method: method
            )
            
        } catch {
            await errorHandler.handleError(error, context: "TimeSeriesAnalysis.detectAnomalies")
            throw error
        }
    }
    
    /// Analyze trends in time series data
    public func analyzeTrend(
        data: TimeSeriesData,
        confidenceLevel: Double = 0.95
    ) async throws -> TrendAnalysis {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("trend_analysis", value: executionTime)
        }
        
        do {
            // Calculate trend slope using linear regression
            let timeValues = Array(0..<data.values.count).map(Double.init)
            let (slope, pValue) = calculateTrendSlope(timeValues: timeValues, values: data.values)
            
            // Determine trend direction
            let trendDirection = determineTrendDirection(slope: slope, pValue: pValue)
            
            // Detect change points
            let changePoints = detectChangePoints(data.values)
            
            return TrendAnalysis(
                slope: slope,
                pValue: pValue,
                confidence: confidenceLevel,
                trendDirection: trendDirection,
                changePoints: changePoints
            )
            
        } catch {
            await errorHandler.handleError(error, context: "TimeSeriesAnalysis.analyzeTrend")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func performARForecasting(
        data: [Double],
        order: Int,
        horizon: Int
    ) async throws -> ([Double], [Double], Double) {
        
        // Fit AR model using Yule-Walker equations
        let coefficients = try calculateARCoefficients(data: data, order: order)
        
        // Generate forecasts
        var predictions: [Double] = []
        var workingData = data
        
        for _ in 0..<horizon {
            var prediction = 0.0
            for i in 0..<min(order, workingData.count) {
                prediction += coefficients[i] * workingData[workingData.count - 1 - i]
            }
            predictions.append(prediction)
            workingData.append(prediction)
        }
        
        // Calculate residuals for accuracy
        let residuals = calculateARResiduals(data: data, coefficients: coefficients, order: order)
        let accuracy = 1.0 - (residuals.map { $0 * $0 }.reduce(0, +) / data.map { $0 * $0 }.reduce(0, +))
        
        return (predictions, residuals, max(0, accuracy))
    }
    
    private func performMAForecasting(
        data: [Double],
        order: Int,
        horizon: Int
    ) async throws -> ([Double], [Double], Double) {
        
        guard order <= data.count else {
            throw AnalyticsError.invalidInput("MA order cannot exceed data length")
        }
        
        // Simple moving average forecast
        let lastValues = Array(data.suffix(order))
        let forecast = lastValues.reduce(0, +) / Double(order)
        let predictions = Array(repeating: forecast, count: horizon)
        
        // Calculate residuals
        var residuals: [Double] = []
        for i in order..<data.count {
            let ma = Array(data[(i-order)..<i]).reduce(0, +) / Double(order)
            residuals.append(data[i] - ma)
        }
        
        let accuracy = 1.0 - (residuals.map { $0 * $0 }.reduce(0, +) / data.map { $0 * $0 }.reduce(0, +))
        
        return (predictions, residuals, max(0, accuracy))
    }
    
    private func performARIMAForecasting(
        data: [Double],
        p: Int, d: Int, q: Int,
        horizon: Int
    ) async throws -> ([Double], [Double], Double) {
        
        // Difference the data d times
        var differencedData = data
        for _ in 0..<d {
            differencedData = Array(zip(differencedData.dropFirst(), differencedData).map { $0 - $1 })
        }
        
        // Fit ARMA model to differenced data
        let arCoefficients = try calculateARCoefficients(data: differencedData, order: p)
        
        // Generate forecasts (simplified ARIMA)
        var predictions: [Double] = []
        var workingData = differencedData
        
        for _ in 0..<horizon {
            var prediction = 0.0
            for i in 0..<min(p, workingData.count) {
                prediction += arCoefficients[i] * workingData[workingData.count - 1 - i]
            }
            predictions.append(prediction)
            workingData.append(prediction)
        }
        
        // Integrate back d times
        for _ in 0..<d {
            for i in 0..<predictions.count {
                if i == 0 {
                    predictions[i] += data.last ?? 0
                } else {
                    predictions[i] += predictions[i - 1]
                }
            }
        }
        
        let residuals = calculateARResiduals(data: differencedData, coefficients: arCoefficients, order: p)
        let accuracy = 1.0 - (residuals.map { $0 * $0 }.reduce(0, +) / differencedData.map { $0 * $0 }.reduce(0, +))
        
        return (predictions, residuals, max(0, accuracy))
    }
    
    private func performExponentialSmoothing(
        data: [Double],
        horizon: Int
    ) async throws -> ([Double], [Double], Double) {
        
        let alpha = 0.3 // Smoothing parameter
        
        // Calculate smoothed values
        var smoothed = [data[0]]
        for i in 1..<data.count {
            let value = alpha * data[i] + (1 - alpha) * smoothed[i - 1]
            smoothed.append(value)
        }
        
        // Forecast
        let lastSmoothed = smoothed.last ?? 0
        let predictions = Array(repeating: lastSmoothed, count: horizon)
        
        // Calculate residuals
        let residuals = zip(data, smoothed).map { $0 - $1 }
        let accuracy = 1.0 - (residuals.map { $0 * $0 }.reduce(0, +) / data.map { $0 * $0 }.reduce(0, +))
        
        return (predictions, residuals, max(0, accuracy))
    }
    
    private func performSeasonalForecasting(
        data: [Double],
        horizon: Int
    ) async throws -> ([Double], [Double], Double) {
        
        let decomposition = try await performSeasonalDecomposition(
            data: TimeSeriesData(timestamps: [], values: data, metadata: [:])
        )
        
        // Project trend
        let trendSlope = calculateTrendSlope(
            timeValues: Array(0..<decomposition.trend.count).map(Double.init),
            values: decomposition.trend
        ).0
        
        let lastTrend = decomposition.trend.last ?? 0
        var futureTrend: [Double] = []
        for i in 1...horizon {
            futureTrend.append(lastTrend + trendSlope * Double(i))
        }
        
        // Extend seasonal pattern
        let seasonalPeriod = decomposition.seasonalPeriod
        var futureSeasonal: [Double] = []
        for i in 0..<horizon {
            let seasonalIndex = (decomposition.seasonal.count + i) % seasonalPeriod
            futureSeasonal.append(decomposition.seasonal[seasonalIndex])
        }
        
        // Combine trend and seasonal
        let predictions = zip(futureTrend, futureSeasonal).map { $0 + $1 }
        
        let accuracy = 1.0 - (decomposition.residual.map { $0 * $0 }.reduce(0, +) / data.map { $0 * $0 }.reduce(0, +))
        
        return (predictions, decomposition.residual, max(0, accuracy))
    }
    
    private func performProphetForecasting(
        data: TimeSeriesData,
        horizon: Int
    ) async throws -> ([Double], [Double], Double) {
        
        // Simplified Prophet-like model
        // In a real implementation, you'd use the actual Prophet library
        
        // Trend component
        let timeValues = Array(0..<data.values.count).map(Double.init)
        let (slope, _) = calculateTrendSlope(timeValues: timeValues, values: data.values)
        
        // Seasonal component (weekly pattern for healthcare data)
        let weeklyPattern = calculateWeeklyPattern(data: data)
        
        // Generate forecasts
        var predictions: [Double] = []
        let lastValue = data.values.last ?? 0
        let lastTime = Double(data.values.count - 1)
        
        for i in 1...horizon {
            let futureTime = lastTime + Double(i)
            let trend = lastValue + slope * Double(i)
            let seasonal = weeklyPattern[i % 7]
            predictions.append(trend + seasonal)
        }
        
        // Calculate residuals (simplified)
        let fitted = timeValues.map { time in
            let trend = (data.values.first ?? 0) + slope * time
            let seasonal = weeklyPattern[Int(time) % 7]
            return trend + seasonal
        }
        
        let residuals = zip(data.values, fitted).map { $0 - $1 }
        let accuracy = 1.0 - (residuals.map { $0 * $0 }.reduce(0, +) / data.values.map { $0 * $0 }.reduce(0, +))
        
        return (predictions, residuals, max(0, accuracy))
    }
    
    // MARK: - Helper Methods
    
    private func calculateARCoefficients(data: [Double], order: Int) throws -> [Double] {
        guard order > 0 && order < data.count else {
            throw AnalyticsError.invalidInput("Invalid AR order")
        }
        
        // Yule-Walker equations for AR coefficients
        // Calculate autocorrelations
        var autocorrelations: [Double] = []
        for lag in 0...order {
            autocorrelations.append(calculateAutocorrelation(data: data, lag: lag))
        }
        
        // Solve Yule-Walker equations
        var matrix = Array(repeating: Array(repeating: 0.0, count: order), count: order)
        for i in 0..<order {
            for j in 0..<order {
                matrix[i][j] = autocorrelations[abs(i - j)]
            }
        }
        
        let rhs = Array(autocorrelations.dropFirst())
        
        // Simplified solution (in practice, use proper linear algebra library)
        if order == 1 {
            return [autocorrelations[1] / autocorrelations[0]]
        } else {
            // Use Levinson-Durbin recursion for efficient solution
            return try levinsonDurbinRecursion(autocorrelations: autocorrelations)
        }
    }
    
    private func calculateAutocorrelation(data: [Double], lag: Int) -> Double {
        guard lag >= 0 && lag < data.count else { return 0.0 }
        
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        
        guard variance > 0 else { return 0.0 }
        
        var covariance = 0.0
        let n = data.count - lag
        
        for i in 0..<n {
            covariance += (data[i] - mean) * (data[i + lag] - mean)
        }
        
        covariance /= Double(data.count)
        return covariance / variance
    }
    
    private func levinsonDurbinRecursion(autocorrelations: [Double]) throws -> [Double] {
        let order = autocorrelations.count - 1
        var coefficients = Array(repeating: 0.0, count: order)
        
        coefficients[0] = autocorrelations[1] / autocorrelations[0]
        var error = autocorrelations[0] * (1 - coefficients[0] * coefficients[0])
        
        for m in 1..<order {
            var sum = 0.0
            for j in 0..<m {
                sum += coefficients[j] * autocorrelations[m - j]
            }
            
            let reflection = (autocorrelations[m + 1] - sum) / error
            coefficients[m] = reflection
            
            for j in 0..<m {
                let temp = coefficients[j]
                coefficients[j] = temp - reflection * coefficients[m - 1 - j]
            }
            
            error *= (1 - reflection * reflection)
        }
        
        return coefficients
    }
    
    private func calculateARResiduals(data: [Double], coefficients: [Double], order: Int) -> [Double] {
        var residuals: [Double] = []
        
        for i in order..<data.count {
            var prediction = 0.0
            for j in 0..<order {
                prediction += coefficients[j] * data[i - 1 - j]
            }
            residuals.append(data[i] - prediction)
        }
        
        return residuals
    }
    
    private func detectSeasonalPeriod(_ data: [Double]) -> Int {
        // Simple seasonal period detection using autocorrelation
        var maxCorrelation = 0.0
        var bestPeriod = 7 // Default to weekly
        
        for period in 2...min(data.count / 3, 365) {
            let correlation = calculateAutocorrelation(data: data, lag: period)
            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestPeriod = period
            }
        }
        
        return bestPeriod
    }
    
    private func extractTrend(_ data: [Double], period: Int) -> [Double] {
        let windowSize = period
        var trend: [Double] = []
        
        for i in 0..<data.count {
            let start = max(0, i - windowSize / 2)
            let end = min(data.count, i + windowSize / 2 + 1)
            let window = Array(data[start..<end])
            let average = window.reduce(0, +) / Double(window.count)
            trend.append(average)
        }
        
        return trend
    }
    
    private func extractSeasonal(_ detrended: [Double], period: Int) -> [Double] {
        var seasonal = Array(repeating: 0.0, count: detrended.count)
        var seasonalPattern = Array(repeating: 0.0, count: period)
        var counts = Array(repeating: 0, count: period)
        
        // Calculate average for each position in the cycle
        for i in 0..<detrended.count {
            let position = i % period
            seasonalPattern[position] += detrended[i]
            counts[position] += 1
        }
        
        for i in 0..<period {
            if counts[i] > 0 {
                seasonalPattern[i] /= Double(counts[i])
            }
        }
        
        // Apply pattern to all data points
        for i in 0..<detrended.count {
            seasonal[i] = seasonalPattern[i % period]
        }
        
        return seasonal
    }
    
    private func calculateSeasonalStrength(seasonal: [Double], residual: [Double]) -> Double {
        let seasonalVariance = seasonal.map { $0 * $0 }.reduce(0, +) / Double(seasonal.count)
        let residualVariance = residual.map { $0 * $0 }.reduce(0, +) / Double(residual.count)
        
        return seasonalVariance / (seasonalVariance + residualVariance)
    }
    
    private func calculateZScores(_ data: [Double]) -> [Double] {
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let standardDeviation = sqrt(variance)
        
        guard standardDeviation > 0 else {
            return Array(repeating: 0.0, count: data.count)
        }
        
        return data.map { ($0 - mean) / standardDeviation }
    }
    
    private func calculateIQRScores(_ data: [Double]) -> [Double] {
        let sortedData = data.sorted()
        let n = sortedData.count
        let q1 = sortedData[n / 4]
        let q3 = sortedData[3 * n / 4]
        let iqr = q3 - q1
        
        guard iqr > 0 else {
            return Array(repeating: 0.0, count: data.count)
        }
        
        return data.map { value in
            if value < q1 - 1.5 * iqr {
                return (q1 - 1.5 * iqr - value) / iqr
            } else if value > q3 + 1.5 * iqr {
                return (value - q3 - 1.5 * iqr) / iqr
            } else {
                return 0.0
            }
        }
    }
    
    private func calculateIsolationForestScores(_ data: [Double]) -> [Double] {
        // Simplified isolation forest implementation
        let numTrees = 10
        let subsampleSize = min(256, data.count)
        var scores: [Double] = Array(repeating: 0.0, count: data.count)
        
        for _ in 0..<numTrees {
            let subsample = Array(data.shuffled().prefix(subsampleSize))
            let tree = buildIsolationTree(subsample, depth: 0, maxDepth: Int(log2(Double(subsampleSize))))
            
            for i in 0..<data.count {
                scores[i] += Double(pathLength(tree: tree, value: data[i], depth: 0))
            }
        }
        
        let avgPathLength = log2(Double(subsampleSize))
        return scores.map { $0 / Double(numTrees) / avgPathLength }
    }
    
    private func calculateStatisticalAnomalyScores(_ data: [Double]) -> [Double] {
        let windowSize = min(10, data.count / 4)
        var scores: [Double] = []
        
        for i in 0..<data.count {
            let start = max(0, i - windowSize)
            let end = min(data.count, i + windowSize + 1)
            let window = Array(data[start..<end])
            
            let mean = window.reduce(0, +) / Double(window.count)
            let variance = window.map { pow($0 - mean, 2) }.reduce(0, +) / Double(window.count)
            let standardDeviation = sqrt(variance)
            
            let score = standardDeviation > 0 ? abs(data[i] - mean) / standardDeviation : 0.0
            scores.append(score)
        }
        
        return scores
    }
    
    private func calculateTrendSlope(timeValues: [Double], values: [Double]) -> (Double, Double) {
        let n = Double(timeValues.count)
        let sumX = timeValues.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(timeValues, values).map(*).reduce(0, +)
        let sumXX = timeValues.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        
        // Simplified p-value calculation
        let predictions = timeValues.map { sumY / n + slope * ($0 - sumX / n) }
        let residuals = zip(values, predictions).map { $0 - $1 }
        let mse = residuals.map { $0 * $0 }.reduce(0, +) / (n - 2)
        let seSlope = sqrt(mse / (sumXX - sumX * sumX / n))
        let tStat = slope / seSlope
        let pValue = 2 * (1 - cumulativeNormalDistribution(abs(tStat)))
        
        return (slope, pValue)
    }
    
    private func determineTrendDirection(slope: Double, pValue: Double) -> TrendDirection {
        let significanceLevel = 0.05
        
        if pValue > significanceLevel {
            return .stable
        } else if slope > 0 {
            return .increasing
        } else if slope < 0 {
            return .decreasing
        } else {
            return .volatile
        }
    }
    
    private func detectChangePoints(_ data: [Double]) -> [Int] {
        // Simple change point detection using sliding window variance
        let windowSize = max(5, data.count / 10)
        var changePoints: [Int] = []
        
        for i in windowSize..<(data.count - windowSize) {
            let beforeWindow = Array(data[(i-windowSize)..<i])
            let afterWindow = Array(data[i..<(i+windowSize)])
            
            let beforeMean = beforeWindow.reduce(0, +) / Double(beforeWindow.count)
            let afterMean = afterWindow.reduce(0, +) / Double(afterWindow.count)
            
            let meanDifference = abs(afterMean - beforeMean)
            let threshold = 2.0 * (beforeWindow + afterWindow).map { $0 * $0 }.reduce(0, +) / Double(2 * windowSize)
            
            if meanDifference > threshold {
                changePoints.append(i)
            }
        }
        
        return changePoints
    }
    
    private func calculateConfidenceIntervals(
        predictions: [Double],
        residuals: [Double],
        confidenceLevel: Double
    ) -> [(lower: Double, upper: Double)] {
        
        let standardError = sqrt(residuals.map { $0 * $0 }.reduce(0, +) / Double(residuals.count))
        let zValue = 1.96 // For 95% confidence
        
        return predictions.map { prediction in
            let margin = zValue * standardError
            return (lower: prediction - margin, upper: prediction + margin)
        }
    }
    
    private func generateFutureTimestamps(lastTimestamp: Date, count: Int) -> [Date] {
        var timestamps: [Date] = []
        let calendar = Calendar.current
        
        for i in 1...count {
            let futureDate = calendar.date(byAdding: .day, value: i, to: lastTimestamp) ?? lastTimestamp
            timestamps.append(futureDate)
        }
        
        return timestamps
    }
    
    private func calculateWeeklyPattern(data: TimeSeriesData) -> [Double] {
        // Calculate average value for each day of the week
        var dailyTotals = Array(repeating: 0.0, count: 7)
        var dailyCounts = Array(repeating: 0, count: 7)
        
        let calendar = Calendar.current
        for (timestamp, value) in zip(data.timestamps, data.values) {
            let dayOfWeek = calendar.component(.weekday, from: timestamp) - 1
            dailyTotals[dayOfWeek] += value
            dailyCounts[dayOfWeek] += 1
        }
        
        var pattern: [Double] = []
        for i in 0..<7 {
            if dailyCounts[i] > 0 {
                pattern.append(dailyTotals[i] / Double(dailyCounts[i]))
            } else {
                pattern.append(0.0)
            }
        }
        
        // Normalize pattern (remove average)
        let patternMean = pattern.reduce(0, +) / Double(pattern.count)
        return pattern.map { $0 - patternMean }
    }
    
    // Simplified isolation tree structures
    private struct IsolationNode {
        let isLeaf: Bool
        let splitValue: Double?
        let left: IsolationNode?
        let right: IsolationNode?
        let size: Int
    }
    
    private func buildIsolationTree(_ data: [Double], depth: Int, maxDepth: Int) -> IsolationNode {
        if depth >= maxDepth || data.count <= 1 {
            return IsolationNode(isLeaf: true, splitValue: nil, left: nil, right: nil, size: data.count)
        }
        
        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 0
        let splitValue = Double.random(in: minVal...maxVal)
        
        let leftData = data.filter { $0 < splitValue }
        let rightData = data.filter { $0 >= splitValue }
        
        let left = buildIsolationTree(leftData, depth: depth + 1, maxDepth: maxDepth)
        let right = buildIsolationTree(rightData, depth: depth + 1, maxDepth: maxDepth)
        
        return IsolationNode(isLeaf: false, splitValue: splitValue, left: left, right: right, size: data.count)
    }
    
    private func pathLength(tree: IsolationNode, value: Double, depth: Int) -> Int {
        if tree.isLeaf {
            return depth
        }
        
        guard let splitValue = tree.splitValue else { return depth }
        
        if value < splitValue {
            return pathLength(tree: tree.left!, value: value, depth: depth + 1)
        } else {
            return pathLength(tree: tree.right!, value: value, depth: depth + 1)
        }
    }
    
    private func cumulativeNormalDistribution(_ x: Double) -> Double {
        return 0.5 * (1 + erf(x / sqrt(2)))
    }
    
    private func zip3<A, B, C>(_ seq1: [A], _ seq2: [B], _ seq3: [C]) -> [(A, B, C)] {
        return zip(zip(seq1, seq2), seq3).map { ($0.0, $0.1, $1) }
    }
}

// MARK: - Health-Specific Time Series Analysis

extension TimeSeriesAnalysis {
    
    /// Analyze vital signs trends over time
    public func analyzeVitalSignsTrends(
        heartRateData: TimeSeriesData,
        bloodPressureData: TimeSeriesData
    ) async throws -> [String: TrendAnalysis] {
        
        let heartRateTrend = try await analyzeTrend(data: heartRateData)
        let bloodPressureTrend = try await analyzeTrend(data: bloodPressureData)
        
        return [
            "heart_rate": heartRateTrend,
            "blood_pressure": bloodPressureTrend
        ]
    }
    
    /// Predict medication adherence patterns
    public func predictMedicationAdherence(
        adherenceData: TimeSeriesData,
        forecastDays: Int = 7
    ) async throws -> ForecastResult {
        
        return try await forecastTimeSeries(
            data: adherenceData,
            model: .arima(p: 1, d: 1, q: 1),
            forecastHorizon: forecastDays
        )
    }
    
    /// Detect anomalies in patient monitoring data
    public func detectPatientMonitoringAnomalies(
        monitoringData: TimeSeriesData
    ) async throws -> AnomalyDetection {
        
        return try await detectAnomalies(
            data: monitoringData,
            method: "statistical",
            threshold: 2.5
        )
    }
}
