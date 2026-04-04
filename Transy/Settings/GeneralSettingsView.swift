import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    let settingsStore: SettingsStore

    @State private var supportedLanguages: [SupportedLanguageOption] = []
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
        }
        .onChange(of: settingsStore.targetLanguage) { _, _ in
            reconcileSelectedLanguage()
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
}
