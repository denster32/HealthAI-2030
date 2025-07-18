import SwiftUI

struct LanguageSwitcherView: View {
    @State private var selectedLanguage = "en"
    @State private var showingLanguagePicker = false
    
    private let supportedLanguages = [
        ("en", "English", "🇺🇸"),
        ("es", "Español", "🇪🇸"),
        ("fr", "Français", "🇫🇷")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Language Display
            VStack(spacing: 12) {
                Text(NSLocalizedString("Current Language", comment: "Current language label"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text(flagForLanguage(selectedLanguage))
                        .font(.title)
                    Text(nameForLanguage(selectedLanguage))
                        .font(.title2)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Language Selection Button
            Button(action: {
                showingLanguagePicker = true
            }) {
                HStack {
                    Image(systemName: "globe")
                        .font(.title2)
                    Text(NSLocalizedString("Change Language", comment: "Change language button"))
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Language Information
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString("Supported Languages", comment: "Supported languages section title"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ForEach(supportedLanguages, id: \.0) { language in
                    HStack {
                        Text(language.2)
                            .font(.title2)
                        Text(language.1)
                            .font(.subheadline)
                        Spacer()
                        if language.0 == selectedLanguage {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .navigationTitle(NSLocalizedString("Language Settings", comment: "Language settings navigation title"))
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(selectedLanguage: $selectedLanguage)
        }
    }
    
    private func flagForLanguage(_ languageCode: String) -> String {
        return supportedLanguages.first { $0.0 == languageCode }?.2 ?? "🌐"
    }
    
    private func nameForLanguage(_ languageCode: String) -> String {
        return supportedLanguages.first { $0.0 == languageCode }?.1 ?? "Unknown"
    }
}

struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.presentationMode) var presentationMode
    
    private let supportedLanguages = [
        ("en", "English", "🇺🇸"),
        ("es", "Español", "🇪🇸"),
        ("fr", "Français", "🇫🇷")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(supportedLanguages, id: \.0) { language in
                    Button(action: {
                        selectedLanguage = language.0
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(language.2)
                                .font(.title2)
                            Text(language.1)
                                .font(.body)
                            Spacer()
                            if language.0 == selectedLanguage {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle(NSLocalizedString("Select Language", comment: "Language picker navigation title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    NavigationView {
        LanguageSwitcherView()
    }
} 