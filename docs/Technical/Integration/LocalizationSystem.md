# Localization & Internationalization System

## Overview

The HealthAI 2030 app implements a comprehensive localization and internationalization system that supports multiple languages and regions. This system ensures that the app can be used by users worldwide with appropriate language support and cultural adaptations.

## Supported Languages

The app currently supports the following languages:

- **English (en)** - Default language
- **Spanish (es)** - Español
- **French (fr)** - Français

## Architecture

### 1. Localization Files Structure

```
Apps/MainApp/Resources/Localization/
├── en.lproj/
│   └── Localizable.strings
├── es.lproj/
│   └── Localizable.strings
└── fr.lproj/
    └── Localizable.strings
```

### 2. String Localization

All user-facing strings are localized using `NSLocalizedString`:

```swift
// Instead of hardcoded strings
Text("Health Goals")

// Use localized strings
Text(NSLocalizedString("Health Goals", comment: "Navigation title for health goals"))
```

### 3. Language Switcher Component

The `LanguageSwitcherView` provides a user interface for changing the app's language:

```swift
struct LanguageSwitcherView: View {
    @State private var selectedLanguage = "en"
    @State private var showingLanguagePicker = false
    
    private let supportedLanguages = [
        ("en", "English", "🇺🇸"),
        ("es", "Español", "🇪🇸"),
        ("fr", "Français", "🇫🇷")
    ]
    
    // Implementation...
}
```

## Implementation Details

### 1. String Localization

#### Basic Usage

```swift
// Navigation titles
.navigationTitle(NSLocalizedString("Health Goals", comment: "Navigation title for health goals"))

// Button labels
Button(NSLocalizedString("Create Goal", comment: "Create goal button")) {
    // Action
}

// Form labels
TextField(NSLocalizedString("Title", comment: "Goal title field"), text: $title)
```

#### Tab Selection

```swift
ForEach([
    NSLocalizedString("Goals", comment: "Goals tab"),
    NSLocalizedString("Progress", comment: "Progress tab"),
    NSLocalizedString("Analytics", comment: "Analytics tab")
], id: \.self) { tab in
    // Tab content
}
```

### 2. Localization Files

#### English (en.lproj/Localizable.strings)

```strings
/* Navigation title for health goals */
"Health Goals" = "Health Goals";

/* Goals tab */
"Goals" = "Goals";

/* Progress tab */
"Progress" = "Progress";

/* Analytics tab */
"Analytics" = "Analytics";

/* Goal title field */
"Title" = "Title";

/* Goal description field */
"Description" = "Description";

/* Create goal button */
"Create Goal" = "Create Goal";

/* Cancel button */
"Cancel" = "Cancel";
```

#### Spanish (es.lproj/Localizable.strings)

```strings
/* Navigation title for health goals */
"Health Goals" = "Objetivos de Salud";

/* Goals tab */
"Goals" = "Objetivos";

/* Progress tab */
"Progress" = "Progreso";

/* Analytics tab */
"Analytics" = "Análisis";

/* Goal title field */
"Title" = "Título";

/* Goal description field */
"Description" = "Descripción";

/* Create goal button */
"Create Goal" = "Crear Objetivo";

/* Cancel button */
"Cancel" = "Cancelar";
```

#### French (fr.lproj/Localizable.strings)

```strings
/* Navigation title for health goals */
"Health Goals" = "Objectifs de Santé";

/* Goals tab */
"Goals" = "Objectifs";

/* Progress tab */
"Progress" = "Progrès";

/* Analytics tab */
"Analytics" = "Analyses";

/* Goal title field */
"Title" = "Titre";

/* Goal description field */
"Description" = "Description";

/* Create goal button */
"Create Goal" = "Créer un Objectif";

/* Cancel button */
"Cancel" = "Annuler";
```

### 3. Language Switching

#### Language Switcher View

The `LanguageSwitcherView` provides:

- Current language display with flag and name
- Language selection button
- List of supported languages
- Language picker sheet

#### Language Picker

The `LanguagePickerView` provides:

- List of all supported languages
- Visual indicators for current selection
- Easy language switching

## Testing

### Unit Tests

The localization system includes comprehensive unit tests in `Tests/Features/LocalizationTests.swift`:

#### Test Categories

1. **Basic String Localization**
   - Tests that basic strings are properly localized
   - Verifies non-empty localized strings

2. **Form Labels Localization**
   - Tests form field labels
   - Tests picker labels
   - Tests input field placeholders

3. **Button Labels Localization**
   - Tests action button labels
   - Tests navigation button labels

4. **Progress Labels Localization**
   - Tests progress-related labels
   - Tests target and end date labels

5. **Analytics Labels Localization**
   - Tests chart titles
   - Tests analytics section labels

6. **Language Switcher Localization**
   - Tests language switcher UI labels
   - Tests navigation titles

#### Performance Tests

- Tests localization performance under load
- Ensures no performance degradation with repeated calls

#### Edge Cases

- Tests missing localization keys
- Tests empty strings
- Tests special characters

### Test Coverage

```swift
func testBasicStringLocalization() throws {
    let healthGoals = NSLocalizedString("Health Goals", comment: "Navigation title for health goals")
    XCTAssertFalse(healthGoals.isEmpty, "Localized string should not be empty")
    
    let goals = NSLocalizedString("Goals", comment: "Goals tab")
    XCTAssertFalse(goals.isEmpty, "Localized string should not be empty")
}
```

## Best Practices

### 1. String Organization

- Group related strings together in localization files
- Use descriptive comments for context
- Maintain consistent naming conventions

### 2. Comment Guidelines

- Provide clear, descriptive comments for each localized string
- Include context about where the string is used
- Use consistent comment formatting

### 3. Key Naming

- Use descriptive, hierarchical key names
- Avoid generic keys like "OK" or "Cancel" without context
- Include the feature or screen name in the key

### 4. Pluralization

For strings that may have plural forms:

```swift
// Use appropriate pluralization rules
let count = 5
let message = String(format: NSLocalizedString("%d goals", comment: "Number of goals"), count)
```

### 5. Date and Number Formatting

```swift
// Use locale-aware formatting
let formatter = DateFormatter()
formatter.locale = Locale.current
formatter.dateStyle = .medium
let formattedDate = formatter.string(from: date)
```

## Adding New Languages

### 1. Create Language Directory

Create a new `.lproj` directory for the language:

```
Apps/MainApp/Resources/Localization/
└── [language_code].lproj/
    └── Localizable.strings
```

### 2. Add Language to Supported Languages

Update the `supportedLanguages` array in `LanguageSwitcherView`:

```swift
private let supportedLanguages = [
    ("en", "English", "🇺🇸"),
    ("es", "Español", "🇪🇸"),
    ("fr", "Français", "🇫🇷"),
    ("de", "Deutsch", "🇩🇪")  // New language
]
```

### 3. Translate Strings

Add translated strings to the new `Localizable.strings` file:

```strings
/* Navigation title for health goals */
"Health Goals" = "Gesundheitsziele";

/* Goals tab */
"Goals" = "Ziele";

/* Progress tab */
"Progress" = "Fortschritt";
```

### 4. Update Tests

Add the new language to localization tests:

```swift
func testNewLanguageSupport() throws {
    // Test German localization
    let germanPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "de.lproj")
    XCTAssertNotNil(germanPath, "German Localizable.strings should exist")
}
```

## Integration with Existing Features

### 1. Health Goal Engine

The Health Goal Engine has been fully localized:

- Navigation titles
- Tab labels
- Form fields
- Button labels
- Progress indicators
- Analytics labels

### 2. Other Features

All other features in the app follow the same localization pattern:

- Use `NSLocalizedString` for all user-facing text
- Provide descriptive comments
- Test localization thoroughly

## Future Enhancements

### 1. Regional Adaptations

- Currency formatting
- Date/time formatting
- Number formatting
- Address formatting

### 2. RTL Support

- Right-to-left language support
- Text alignment
- Layout direction

### 3. Accessibility

- VoiceOver support for different languages
- Dynamic Type support
- High contrast mode

### 4. Advanced Features

- Automatic language detection
- Language preferences sync
- Contextual language switching

## Troubleshooting

### Common Issues

1. **Missing Localization**
   - Ensure all strings use `NSLocalizedString`
   - Check that localization files exist
   - Verify string keys match across languages

2. **Incorrect Translations**
   - Review translations for accuracy
   - Test with native speakers
   - Use professional translation services

3. **Performance Issues**
   - Cache frequently used strings
   - Avoid repeated localization calls
   - Use appropriate string formatting

### Debugging

```swift
// Enable localization debugging
UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
UserDefaults.standard.synchronize()
```

## Conclusion

The localization system provides a solid foundation for internationalizing the HealthAI 2030 app. By following the established patterns and best practices, new features can be easily localized and the app can reach a global audience effectively.

The system is designed to be:
- **Scalable**: Easy to add new languages
- **Maintainable**: Clear organization and documentation
- **Testable**: Comprehensive test coverage
- **User-friendly**: Intuitive language switching
- **Performance-optimized**: Efficient string lookup and caching 