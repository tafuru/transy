import SwiftUI
import Translation

struct SettingsView: View {
    let settingsStore: SettingsStore
    
    @State private var supportedLanguages: [SupportedLanguageOption] = []
    @State private var guidanceState: TranslationModelGuidance.GuidanceState = .none
    @State private var selectedLanguageID: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Target language picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Language")
                    .font(.headline)
                
                Picker("Target Language", selection: $selectedLanguageID) {
                    ForEach(supportedLanguages) { option in
                        Text(option.displayName)
                            .tag(option.id)
                    }
                }
                .labelsHidden()
                .disabled(supportedLanguages.isEmpty)
                .onChange(of: selectedLanguageID) { _, newID in
                    if let option = supportedLanguages.first(where: { $0.id == newID }) {
                        settingsStore.updateTargetLanguage(option.language)
                    }
                }
            }
            
            // Conditional model guidance
            if guidanceState != .none {
                Divider()
                
                switch guidanceState {
                case .none:
                    EmptyView()
                    
                case .generic:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translation Model Required")
                            .font(.headline)
                        
                        Text("Download the required translation model in System Settings → General → Language & Region → Translation Languages.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Button("Open Language & Region") {
                            openSystemSettings()
                        }
                    }
                    
                case let .pairSpecific(source, target):
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translation Model Required")
                            .font(.headline)
                        
                        let sourceName = Locale.current.localizedString(
                            forIdentifier: source.minimalIdentifier
                        ) ?? source.minimalIdentifier
                        let targetName = Locale.current.localizedString(
                            forIdentifier: target.minimalIdentifier
                        ) ?? target.minimalIdentifier
                        
                        Text("Download the \(sourceName) → \(targetName) model in System Settings → General → Language & Region → Translation Languages.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Button("Open Language & Region") {
                            openSystemSettings()
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 400)
        .task {
            // Load supported languages on appear
            supportedLanguages = await SupportedLanguageOption.loadSupportedLanguages()
            
            // Reconcile stored target language with supported options
            reconcileSelectedLanguage()
            
            // Check guidance state
            let guidance = TranslationModelGuidance(
                missingModelContext: settingsStore.missingModelContext
            )
            guidanceState = await guidance.currentState()
        }
        .onChange(of: settingsStore.targetLanguage) { _, _ in
            reconcileSelectedLanguage()
        }
        .onChange(of: settingsStore.missingModelContext) { _, _ in
            Task {
                let guidance = TranslationModelGuidance(
                    missingModelContext: settingsStore.missingModelContext
                )
                guidanceState = await guidance.currentState()
            }
        }
    }
    
    private func reconcileSelectedLanguage() {
        let storedID = settingsStore.targetLanguage.minimalIdentifier
        
        // If the stored target is in the supported list, use it
        if supportedLanguages.contains(where: { $0.id == storedID }) {
            selectedLanguageID = storedID
        } else if !supportedLanguages.isEmpty {
            // Otherwise, pick the first supported language and update the store
            let fallback = supportedLanguages[0]
            selectedLanguageID = fallback.id
            settingsStore.updateTargetLanguage(fallback.language)
        }
    }
    
    private func openSystemSettings() {
        // Try to open the General > Language & Region pane in System Settings.
        // On macOS 13+ (Ventura), the System Settings app replaced System Preferences,
        // but the x-apple.systempreferences URL scheme is still supported for compatibility.
        // The pane ID com.apple.Localization-Settings maps to Language & Region.
        if let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings") {
            NSWorkspace.shared.open(url)
        }
    }
}
