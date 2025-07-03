import SwiftUI

struct LocalizationSettingsView: View {
    @State private var selectedLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    let supportedLanguages = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "zh": "Chinese",
        "ja": "Japanese",
        "it": "Italian",
        "pt": "Portuguese",
        "ru": "Russian",
        "ar": "Arabic",
        "ko": "Korean"
    ]
    var body: some View {
        Form {
            Picker("Language", selection: $selectedLanguage) {
                ForEach(supportedLanguages.keys.sorted(), id: \.") { code in
                    Text(supportedLanguages[code] ?? code).tag(code)
                }
            }
            .pickerStyle(.inline)
            Text("App will use the selected language where available.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Language & Localization")
    }
}
