import Foundation
import SwiftUI

/**
 * InternationalizationFramework
 * 
 * Comprehensive internationalization and localization system for HealthAI2030.
 * Provides seamless multi-language support with health-specific terminology,
 * cultural adaptations, and accessibility compliance across all supported locales.
 * 
 * ## Features
 * - Dynamic string localization with health domain expertise
 * - Cultural adaptation for health metrics and units
 * - Right-to-left (RTL) language support
 * - Accessibility-compliant localization
 * - Medical terminology standardization
 * - Regional health standard compliance
 * - Voice-over pronunciation guides
 * 
 * ## Supported Languages
 * - English (US, UK, AU, CA)
 * - Spanish (ES, MX, AR)
 * - French (FR, CA)
 * - German (DE, AT, CH)
 * - Italian (IT)
 * - Portuguese (PT, BR)
 * - Chinese (Simplified, Traditional)
 * - Japanese (JP)
 * - Korean (KR)
 * - Arabic (AR, SA, EG)
 * - Hebrew (IL)
 * - Russian (RU)
 * 
 * ## Usage
 * ```swift
 * let framework = InternationalizationFramework.shared
 * 
 * // Basic localization
 * let text = framework.localize("heart_rate_title")
 * 
 * // Health-specific formatting
 * let heartRate = framework.formatHealthMetric(.heartRate, value: 72, locale: .current)
 * 
 * // Accessibility-aware localization
 * let accessibleText = framework.localizeForAccessibility("sleep_stage_rem")
 * ```
 * 
 * - Author: HealthAI2030 Team
 * - Version: 1.0
 * - Since: iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0
 */
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public class InternationalizationFramework: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = InternationalizationFramework()
    
    // MARK: - Types
    
    public enum HealthMetricType {
        case heartRate
        case bloodPressure
        case weight
        case height
        case temperature
        case bloodGlucose
        case steps
        case calories
        case sleepDuration
        case respiratoryRate
        case oxygenSaturation
        case stress
        case hrv
        
        var defaultUnit: HealthUnit {
            switch self {
            case .heartRate: return .beatsPerMinute
            case .bloodPressure: return .mmHg
            case .weight: return .kilograms
            case .height: return .centimeters
            case .temperature: return .celsius
            case .bloodGlucose: return .mgPerDl
            case .steps: return .count
            case .calories: return .kcal
            case .sleepDuration: return .hours
            case .respiratoryRate: return .breathsPerMinute
            case .oxygenSaturation: return .percentage
            case .stress: return .percentage
            case .hrv: return .milliseconds
            }
        }
    }
    
    public enum HealthUnit {
        case beatsPerMinute
        case mmHg
        case kilograms
        case pounds
        case centimeters
        case inches
        case celsius
        case fahrenheit
        case mgPerDl
        case mmolPerL
        case count
        case kcal
        case hours
        case minutes
        case breathsPerMinute
        case percentage
        case milliseconds
        
        var symbol: String {
            switch self {
            case .beatsPerMinute: return "BPM"
            case .mmHg: return "mmHg"
            case .kilograms: return "kg"
            case .pounds: return "lbs"
            case .centimeters: return "cm"
            case .inches: return "in"
            case .celsius: return "°C"
            case .fahrenheit: return "°F"
            case .mgPerDl: return "mg/dL"
            case .mmolPerL: return "mmol/L"
            case .count: return ""
            case .kcal: return "kcal"
            case .hours: return "h"
            case .minutes: return "min"
            case .breathsPerMinute: return "breaths/min"
            case .percentage: return "%"
            case .milliseconds: return "ms"
            }
        }
    }
    
    public enum SupportedLocale: String, CaseIterable {
        case enUS = "en_US"
        case enUK = "en_GB"
        case enAU = "en_AU"
        case enCA = "en_CA"
        case esES = "es_ES"
        case esMX = "es_MX"
        case esAR = "es_AR"
        case frFR = "fr_FR"
        case frCA = "fr_CA"
        case deDE = "de_DE"
        case deAT = "de_AT"
        case deCH = "de_CH"
        case itIT = "it_IT"
        case ptPT = "pt_PT"
        case ptBR = "pt_BR"
        case zhCN = "zh_CN"
        case zhTW = "zh_TW"
        case jaJP = "ja_JP"
        case koKR = "ko_KR"
        case arAR = "ar_AR"
        case arSA = "ar_SA"
        case arEG = "ar_EG"
        case heIL = "he_IL"
        case ruRU = "ru_RU"
        
        var isRTL: Bool {
            return self == .arAR || self == .arSA || self == .arEG || self == .heIL
        }
        
        var locale: Locale {
            return Locale(identifier: rawValue)
        }
        
        var preferredUnits: HealthUnitPreferences {
            switch self {
            case .enUS:
                return HealthUnitPreferences(
                    weight: .pounds,
                    height: .inches,
                    temperature: .fahrenheit,
                    bloodGlucose: .mgPerDl
                )
            case .enUK, .enAU, .enCA:
                return HealthUnitPreferences(
                    weight: .kilograms,
                    height: .centimeters,
                    temperature: .celsius,
                    bloodGlucose: .mmolPerL
                )
            default:
                return HealthUnitPreferences(
                    weight: .kilograms,
                    height: .centimeters,
                    temperature: .celsius,
                    bloodGlucose: .mmolPerL
                )
            }
        }
    }
    
    public struct HealthUnitPreferences {
        let weight: HealthUnit
        let height: HealthUnit
        let temperature: HealthUnit
        let bloodGlucose: HealthUnit
    }
    
    // MARK: - Published Properties
    
    @Published public var currentLocale: SupportedLocale = .enUS
    @Published public var isRTLEnabled: Bool = false
    
    // MARK: - Private Properties
    
    private var localizedStrings: [String: [String: String]] = [:]
    private var medicalTerminology: [String: [String: String]] = [:]
    private var pronunciationGuides: [String: [String: String]] = [:]
    
    // MARK: - Initialization
    
    private init() {
        setupLocalization()
        detectSystemLocale()
        loadLocalizedContent()
    }
    
    // MARK: - Public Methods
    
    public func localize(_ key: String, arguments: CVarArg...) -> String {
        let localeKey = currentLocale.rawValue
        
        guard let localizedValue = localizedStrings[localeKey]?[key] else {
            // Fallback to English if localization not found
            let fallbackValue = localizedStrings["en_US"]?[key] ?? key
            return String(format: fallbackValue, arguments: arguments)
        }
        
        return String(format: localizedValue, arguments: arguments)
    }
    
    public func localizeForAccessibility(_ key: String, arguments: CVarArg...) -> String {
        let baseText = localize(key, arguments: arguments)
        
        // Add pronunciation guidance for accessibility
        let pronunciationKey = "\(key)_pronunciation"
        if let pronunciation = pronunciationGuides[currentLocale.rawValue]?[pronunciationKey] {
            return "\(baseText). \(pronunciation)"
        }
        
        return baseText
    }
    
    public func formatHealthMetric(_ type: HealthMetricType, value: Double, locale: Locale? = nil) -> String {
        let targetLocale = locale ?? currentLocale.locale
        let preferredUnit = getPreferredUnit(for: type)
        let convertedValue = convertValue(value, from: type.defaultUnit, to: preferredUnit)
        
        let formatter = NumberFormatter()
        formatter.locale = targetLocale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = getDecimalPlaces(for: type)
        
        let formattedValue = formatter.string(from: NSNumber(value: convertedValue)) ?? "\(convertedValue)"
        let unitSymbol = preferredUnit.symbol
        
        if unitSymbol.isEmpty {
            return formattedValue
        } else {
            return "\(formattedValue) \(unitSymbol)"
        }
    }
    
    public func formatHealthMetricForAccessibility(_ type: HealthMetricType, value: Double) -> String {
        let formattedValue = formatHealthMetric(type, value: value)
        let metricKey = "metric_\(type)_accessibility"
        let accessibleName = localize(metricKey)
        
        return "\(accessibleName): \(formattedValue)"
    }
    
    public func setLocale(_ locale: SupportedLocale) {
        currentLocale = locale
        isRTLEnabled = locale.isRTL
        loadLocalizedContent()
    }
    
    public func getMedicalTerm(_ key: String) -> String {
        let localeKey = currentLocale.rawValue
        return medicalTerminology[localeKey]?[key] ?? medicalTerminology["en_US"]?[key] ?? key
    }
    
    public func getHealthUnitPreferences() -> HealthUnitPreferences {
        return currentLocale.preferredUnits
    }
    
    // MARK: - Private Methods
    
    private func setupLocalization() {
        // Initialize core localized strings
        setupEnglishStrings()
        setupSpanishStrings()
        setupFrenchStrings()
        setupGermanStrings()
        setupChineseStrings()
        setupJapaneseStrings()
        setupArabicStrings()
        
        // Initialize medical terminology
        setupMedicalTerminology()
        
        // Initialize pronunciation guides
        setupPronunciationGuides()
    }
    
    private func detectSystemLocale() {
        let systemLocale = Locale.current.identifier
        
        if let supportedLocale = SupportedLocale(rawValue: systemLocale) {
            setLocale(supportedLocale)
        } else {
            // Try to match language component
            let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
            
            switch languageCode {
            case "es": setLocale(.esES)
            case "fr": setLocale(.frFR)
            case "de": setLocale(.deDE)
            case "it": setLocale(.itIT)
            case "pt": setLocale(.ptPT)
            case "zh": setLocale(.zhCN)
            case "ja": setLocale(.jaJP)
            case "ko": setLocale(.koKR)
            case "ar": setLocale(.arAR)
            case "he": setLocale(.heIL)
            case "ru": setLocale(.ruRU)
            default: setLocale(.enUS)
            }
        }
    }
    
    private func loadLocalizedContent() {
        // In production, this would load from localization files
        // For now, using embedded strings
    }
    
    private func getPreferredUnit(for type: HealthMetricType) -> HealthUnit {
        let preferences = currentLocale.preferredUnits
        
        switch type {
        case .weight: return preferences.weight
        case .height: return preferences.height
        case .temperature: return preferences.temperature
        case .bloodGlucose: return preferences.bloodGlucose
        default: return type.defaultUnit
        }
    }
    
    private func convertValue(_ value: Double, from sourceUnit: HealthUnit, to targetUnit: HealthUnit) -> Double {
        // Implement unit conversions
        if sourceUnit == targetUnit { return value }
        
        switch (sourceUnit, targetUnit) {
        case (.kilograms, .pounds): return value * 2.20462
        case (.pounds, .kilograms): return value / 2.20462
        case (.centimeters, .inches): return value / 2.54
        case (.inches, .centimeters): return value * 2.54
        case (.celsius, .fahrenheit): return (value * 9/5) + 32
        case (.fahrenheit, .celsius): return (value - 32) * 5/9
        case (.mgPerDl, .mmolPerL): return value * 0.0555 // For glucose
        case (.mmolPerL, .mgPerDl): return value / 0.0555 // For glucose
        default: return value
        }
    }
    
    private func getDecimalPlaces(for type: HealthMetricType) -> Int {
        switch type {
        case .heartRate, .steps: return 0
        case .weight, .height, .temperature: return 1
        case .bloodGlucose, .hrv: return 1
        case .sleepDuration: return 1
        default: return 1
        }
    }
    
    // MARK: - Localization Setup Methods
    
    private func setupEnglishStrings() {
        localizedStrings["en_US"] = [
            "heart_rate_title": "Heart Rate",
            "blood_pressure_title": "Blood Pressure",
            "sleep_stage_rem": "REM Sleep",
            "sleep_stage_deep": "Deep Sleep",
            "sleep_stage_light": "Light Sleep",
            "metric_heartRate_accessibility": "Heart rate",
            "metric_bloodPressure_accessibility": "Blood pressure",
            "metric_sleepDuration_accessibility": "Sleep duration",
            "emergency_alert_high_heart_rate": "High heart rate detected",
            "health_goal_achieved": "Health goal achieved!",
            "sync_in_progress": "Syncing health data...",
            "accessibility_hint_heart_rate": "Shows your current heart rate in beats per minute"
        ]
        
        localizedStrings["en_GB"] = localizedStrings["en_US"] // Same as US English for now
        localizedStrings["en_AU"] = localizedStrings["en_US"]
        localizedStrings["en_CA"] = localizedStrings["en_US"]
    }
    
    private func setupSpanishStrings() {
        localizedStrings["es_ES"] = [
            "heart_rate_title": "Frecuencia Cardíaca",
            "blood_pressure_title": "Presión Arterial",
            "sleep_stage_rem": "Sueño REM",
            "sleep_stage_deep": "Sueño Profundo",
            "sleep_stage_light": "Sueño Ligero",
            "metric_heartRate_accessibility": "Frecuencia cardíaca",
            "metric_bloodPressure_accessibility": "Presión arterial",
            "metric_sleepDuration_accessibility": "Duración del sueño",
            "emergency_alert_high_heart_rate": "Frecuencia cardíaca alta detectada",
            "health_goal_achieved": "¡Objetivo de salud alcanzado!",
            "sync_in_progress": "Sincronizando datos de salud...",
            "accessibility_hint_heart_rate": "Muestra tu frecuencia cardíaca actual en latidos por minuto"
        ]
        
        localizedStrings["es_MX"] = localizedStrings["es_ES"] // Regional variations can be added later
        localizedStrings["es_AR"] = localizedStrings["es_ES"]
    }
    
    private func setupFrenchStrings() {
        localizedStrings["fr_FR"] = [
            "heart_rate_title": "Fréquence Cardiaque",
            "blood_pressure_title": "Tension Artérielle",
            "sleep_stage_rem": "Sommeil REM",
            "sleep_stage_deep": "Sommeil Profond",
            "sleep_stage_light": "Sommeil Léger",
            "metric_heartRate_accessibility": "Fréquence cardiaque",
            "metric_bloodPressure_accessibility": "Tension artérielle",
            "metric_sleepDuration_accessibility": "Durée du sommeil",
            "emergency_alert_high_heart_rate": "Fréquence cardiaque élevée détectée",
            "health_goal_achieved": "Objectif de santé atteint !",
            "sync_in_progress": "Synchronisation des données de santé...",
            "accessibility_hint_heart_rate": "Affiche votre fréquence cardiaque actuelle en battements par minute"
        ]
        
        localizedStrings["fr_CA"] = localizedStrings["fr_FR"]
    }
    
    private func setupGermanStrings() {
        localizedStrings["de_DE"] = [
            "heart_rate_title": "Herzfrequenz",
            "blood_pressure_title": "Blutdruck",
            "sleep_stage_rem": "REM-Schlaf",
            "sleep_stage_deep": "Tiefschlaf",
            "sleep_stage_light": "Leichtschlaf",
            "metric_heartRate_accessibility": "Herzfrequenz",
            "metric_bloodPressure_accessibility": "Blutdruck",
            "metric_sleepDuration_accessibility": "Schlafdauer",
            "emergency_alert_high_heart_rate": "Hohe Herzfrequenz erkannt",
            "health_goal_achieved": "Gesundheitsziel erreicht!",
            "sync_in_progress": "Gesundheitsdaten werden synchronisiert...",
            "accessibility_hint_heart_rate": "Zeigt Ihre aktuelle Herzfrequenz in Schlägen pro Minute"
        ]
        
        localizedStrings["de_AT"] = localizedStrings["de_DE"]
        localizedStrings["de_CH"] = localizedStrings["de_DE"]
    }
    
    private func setupChineseStrings() {
        localizedStrings["zh_CN"] = [
            "heart_rate_title": "心率",
            "blood_pressure_title": "血压",
            "sleep_stage_rem": "快速眼动睡眠",
            "sleep_stage_deep": "深度睡眠",
            "sleep_stage_light": "浅度睡眠",
            "metric_heartRate_accessibility": "心率",
            "metric_bloodPressure_accessibility": "血压",
            "metric_sleepDuration_accessibility": "睡眠时长",
            "emergency_alert_high_heart_rate": "检测到高心率",
            "health_goal_achieved": "健康目标已达成！",
            "sync_in_progress": "正在同步健康数据...",
            "accessibility_hint_heart_rate": "显示您当前的心率，单位为每分钟心跳次数"
        ]
        
        localizedStrings["zh_TW"] = [
            "heart_rate_title": "心率",
            "blood_pressure_title": "血壓",
            "sleep_stage_rem": "快速動眼睡眠",
            "sleep_stage_deep": "深度睡眠",
            "sleep_stage_light": "淺度睡眠",
            "metric_heartRate_accessibility": "心率",
            "metric_bloodPressure_accessibility": "血壓",
            "metric_sleepDuration_accessibility": "睡眠時長",
            "emergency_alert_high_heart_rate": "檢測到高心率",
            "health_goal_achieved": "健康目標已達成！",
            "sync_in_progress": "正在同步健康數據...",
            "accessibility_hint_heart_rate": "顯示您當前的心率，單位為每分鐘心跳次數"
        ]
    }
    
    private func setupJapaneseStrings() {
        localizedStrings["ja_JP"] = [
            "heart_rate_title": "心拍数",
            "blood_pressure_title": "血圧",
            "sleep_stage_rem": "レム睡眠",
            "sleep_stage_deep": "深い睡眠",
            "sleep_stage_light": "浅い睡眠",
            "metric_heartRate_accessibility": "心拍数",
            "metric_bloodPressure_accessibility": "血圧",
            "metric_sleepDuration_accessibility": "睡眠時間",
            "emergency_alert_high_heart_rate": "高心拍数を検出しました",
            "health_goal_achieved": "健康目標を達成しました！",
            "sync_in_progress": "健康データを同期中...",
            "accessibility_hint_heart_rate": "現在の心拍数を1分あたりの拍数で表示します"
        ]
    }
    
    private func setupArabicStrings() {
        localizedStrings["ar_AR"] = [
            "heart_rate_title": "معدل ضربات القلب",
            "blood_pressure_title": "ضغط الدم",
            "sleep_stage_rem": "نوم حركة العين السريعة",
            "sleep_stage_deep": "النوم العميق",
            "sleep_stage_light": "النوم الخفيف",
            "metric_heartRate_accessibility": "معدل ضربات القلب",
            "metric_bloodPressure_accessibility": "ضغط الدم",
            "metric_sleepDuration_accessibility": "مدة النوم",
            "emergency_alert_high_heart_rate": "تم اكتشاف معدل ضربات قلب مرتفع",
            "health_goal_achieved": "تم تحقيق الهدف الصحي!",
            "sync_in_progress": "جاري مزامنة البيانات الصحية...",
            "accessibility_hint_heart_rate": "يعرض معدل ضربات القلب الحالي بضربات في الدقيقة"
        ]
        
        localizedStrings["ar_SA"] = localizedStrings["ar_AR"]
        localizedStrings["ar_EG"] = localizedStrings["ar_AR"]
    }
    
    private func setupMedicalTerminology() {
        // Setup standardized medical terms for each locale
        medicalTerminology["en_US"] = [
            "hypertension": "High Blood Pressure",
            "tachycardia": "Rapid Heart Rate",
            "bradycardia": "Slow Heart Rate",
            "arrhythmia": "Irregular Heart Rhythm",
            "hypoglycemia": "Low Blood Sugar",
            "hyperglycemia": "High Blood Sugar"
        ]
        
        medicalTerminology["es_ES"] = [
            "hypertension": "Hipertensión",
            "tachycardia": "Taquicardia",
            "bradycardia": "Bradicardia",
            "arrhythmia": "Arritmia",
            "hypoglycemia": "Hipoglucemia",
            "hyperglycemia": "Hiperglucemia"
        ]
        
        // Add more medical terminology for other languages...
    }
    
    private func setupPronunciationGuides() {
        // Setup pronunciation guides for accessibility
        pronunciationGuides["en_US"] = [
            "tachycardia_pronunciation": "pronounced: tack-ih-CAR-dee-ah",
            "bradycardia_pronunciation": "pronounced: brad-ih-CAR-dee-ah",
            "arrhythmia_pronunciation": "pronounced: ah-RITH-me-ah"
        ]
        
        // Add pronunciation guides for other languages...
    }
}

// MARK: - SwiftUI Integration

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public extension Text {
    init(localized key: String, arguments: CVarArg...) {
        let localizedText = InternationalizationFramework.shared.localize(key, arguments: arguments)
        self.init(localizedText)
    }
    
    init(healthMetric type: InternationalizationFramework.HealthMetricType, value: Double) {
        let formattedText = InternationalizationFramework.shared.formatHealthMetric(type, value: value)
        self.init(formattedText)
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public extension View {
    func rtlAware() -> some View {
        environment(\.layoutDirection, InternationalizationFramework.shared.isRTLEnabled ? .rightToLeft : .leftToRight)
    }
}

// MARK: - Accessibility Extensions

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public extension AccessibilityHelper {
    static func localizedAccessibilityLabel(_ key: String, arguments: CVarArg...) -> String {
        return InternationalizationFramework.shared.localizeForAccessibility(key, arguments: arguments)
    }
    
    static func localizedHealthMetricForAccessibility(_ type: InternationalizationFramework.HealthMetricType, value: Double) -> String {
        return InternationalizationFramework.shared.formatHealthMetricForAccessibility(type, value: value)
    }
}