import SwiftUI
import Translation

struct SettingsView: View {
    let settingsStore: SettingsStore
    
    @State private var supportedLanguages: [SupportedLanguageOption] = []
    @State private var guidanceState: TranslationModelGuidance.GuidanceState = .none
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Target language picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Language")
                    .font(.headline)
                
                Picker("Target Language", selection: Binding(
                    get: { settingsStore.targetLanguage.minimalIdentifier },
                    set: { newID in
                        if let option = supportedLanguages.first(where: { $0.id == newID }) {
                            settingsStore.updateTargetLanguage(option.language)
                        }
                    }
                )) {
                    ForEach(supportedLanguages) { option in
                        Text(option.displayName)
                            .tag(option.id)
                    }
                }
                .labelsHidden()
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
                        
                        Text("A translation model is required. Download it in System Settings.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Button("Open System Settings") {
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
                        
                        Text("The \(sourceName) → \(targetName) translation model is required. Download it in System Settings.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Button("Open System Settings") {
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
            
            // Check guidance state
            let guidance = TranslationModelGuidance(
                missingModelContext: settingsStore.missingModelContext
            )
            guidanceState = await guidance.currentState()
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
    
    private func openSystemSettings() {
        // Conservative fallback: open Language & Region in System Settings
        // This is more reliable than a deep link that might not exist
        if let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings") {
            NSWorkspace.shared.open(url)
        }
    }
}
