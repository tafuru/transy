import ServiceManagement
import SwiftUI
import Translation

struct GeneralSettingsView: View {
    let settingsStore: SettingsStore

    @State private var supportedLanguages: [SupportedLanguageOption] = []
    @State private var guidanceState: TranslationModelGuidance.GuidanceState = .none
    @State private var selectedLanguageID: String = ""
    @State private var launchAtLogin: Bool = false

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin },
            set: { newValue in
                if newValue {
                    try? SMAppService.mainApp.register()
                } else {
                    try? SMAppService.mainApp.unregister()
                }
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        )
    }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: launchAtLoginBinding)
            }

            Section("Translation") {
                Picker("Target Language", selection: $selectedLanguageID) {
                    ForEach(supportedLanguages) { option in
                        Text(option.displayName)
                            .tag(option.id)
                    }
                }
                .disabled(supportedLanguages.isEmpty)
                .onChange(of: selectedLanguageID) { _, newID in
                    if let option = supportedLanguages.first(where: { $0.id == newID }) {
                        settingsStore.updateTargetLanguage(option.language)
                    }
                }

                // Conditional model guidance
                if guidanceState != .none {
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
        }
        .formStyle(.grouped)
        .task {
            // Initialize launch at login toggle from actual system state
            launchAtLogin = SMAppService.mainApp.status == .enabled

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

        // Exact match — stored ID is directly in the supported list
        if supportedLanguages.contains(where: { $0.id == storedID }) {
            selectedLanguageID = storedID
            return
        }

        // Fuzzy match — stored ID includes a region (e.g. "en-JP") but supported
        // list uses the bare language code (e.g. "en"). Match by languageCode.
        if let languageCode = settingsStore.targetLanguage.languageCode,
           let match = supportedLanguages.first(where: {
               $0.language.languageCode == languageCode
           }) {
            selectedLanguageID = match.id
            settingsStore.updateTargetLanguage(match.language)
            return
        }

        // No match at all — fall back to first supported language
        if let fallback = supportedLanguages.first {
            selectedLanguageID = fallback.id
            settingsStore.updateTargetLanguage(fallback.language)
        }
    }

    private func openSystemSettings() {
        // Open General > Language & Region in System Settings.
        // The .extension suffix is required on macOS 13+ (Ventura and later) to target
        // the correct pane in the new System Settings app.
        if let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
