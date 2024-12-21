import SwiftUI
import ActivityKit

import Defaults

#if os(macOS)
struct ReadingSettings: View {
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom

    var body: some View {
        let isSnippet = Binding {
            switch searchResultSnippetMode {
            case .matches: return true
            case .disabled: return false
            }
        } set: { isOn in
            searchResultSnippetMode = isOn ? .matches : .disabled
        }
        VStack(spacing: 16) {
            SettingSection(name: "reading_settings.zoom.title".localized) {
                HStack {
                    Stepper(webViewPageZoom.formatted(.percent), value: $webViewPageZoom, in: 0.5...2, step: 0.05)
                    Spacer()
                    Button("reading_settings.zoom.reset.button".localized) {
                        webViewPageZoom = 1
                    }.disabled(webViewPageZoom == 1)
                }
            }
            if FeatureFlags.showExternalLinkOptionInSettings {
                SettingSection(name: "reading_settings.external_link.title".localized) {
                    Picker(selection: $externalLinkLoadingPolicy) {
                        ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                            Text(loadingPolicy.name).tag(loadingPolicy)
                        }
                    } label: { }
                }
            }
            if FeatureFlags.showSearchSnippetInSettings {
                SettingSection(name: "reading_settings.search_snippet.title".localized) {
                    Toggle(" ", isOn: isSnippet)
                }
            }
        }
        .padding()
        .tabItem { Label("reading_settings.tab.reading".localized, systemImage: "book") }
    }
}

struct LibrarySettings: View {
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @EnvironmentObject private var library: LibraryViewModel

    var body: some View {
        VStack(spacing: 16) {
            SettingSection(name: "library_settings.catalog.title".localized, alignment: .top) {
                HStack(spacing: 6) {
                    Button("library_settings.button.refresh_now".localized) {
                        library.start(isUserInitiated: true)
                    }.disabled(library.state == .inProgress)
                    if library.state == .inProgress {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                    }
                    Spacer()
                    if library.state == .error {
                        Text("library_refresh_error.retrieve.description".localized).foregroundColor(.red)
                    } else {
                        Text("library_settings.last_refresh.text".localized + ":").foregroundColor(.secondary)
                        LibraryLastRefreshTime().foregroundColor(.secondary)
                    }

                }
                VStack(alignment: .leading) {
                    Toggle("library_settings.auto_refresh.toggle".localized, isOn: $libraryAutoRefresh)
                    Text("library_settings.catalog_warning.text".localized)
                        .foregroundColor(.secondary)
                }
            }
            SettingSection(name: "library_settings.languages.title".localized, alignment: .top) {
                LanguageSelector()
            }
        }
        .padding()
        .tabItem { Label("library_settings.tab.library.title".localized, systemImage: "folder.badge.gearshape") }
    }
}

struct SettingSection<Content: View>: View {
    let name: String
    let alignment: VerticalAlignment
    var content: () -> Content

    init(
        name: String,
        alignment: VerticalAlignment = .firstTextBaseline,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.name = name
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        HStack(alignment: alignment) {
            Text("\(name):").frame(width: 100, alignment: .trailing)
            VStack(alignment: .leading, spacing: 16, content: content)
            Spacer()
        }
    }
}

#elseif os(iOS)

import PassKit
import Combine

struct Settings: View {

    enum DonationPopupState {
        case selection
        case selectedAmount(SelectedAmount)
        case thankYou
        case error
    }

    private var amountSelected = PassthroughSubject<SelectedAmount?, Never>()
    @State private var showDonationPopUp: Bool = false
    @State private var donationPopUpState: DonationPopupState = .selection
    func openDonation() {
        showDonationPopUp = true
    }
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom
    @Default(.enableLiveActivities) private var enableLiveActivities
    @EnvironmentObject private var library: LibraryViewModel

    enum Route {
        case languageSelector, about
    }

    var body: some View {
        Group {
            if FeatureFlags.hasLibrary {
                List {
                    readingSettings
                    librarySettings
                    catalogSettings
                    backupSettings
                    miscellaneous
                }
                .modifier(ToolbarRoleBrowser())
                .navigationTitle("settings.navigation.title".localized)
            } else {
                List {
                    readingSettings
                    miscellaneous
                }
                .modifier(ToolbarRoleBrowser())
                .navigationTitle("settings.navigation.title".localized)
            }
        }
        .sheet(isPresented: $showDonationPopUp, onDismiss: {
            let result = Payment.showResult()
            switch result {
            case .none:
                // reset
                donationPopUpState = .selection
                return
            case .some(let finalResult):
                Task {
                    // we need to close the sheet in order to dismiss ApplePay,
                    // and we need to re-open it again with a delay to show thank you state
                    // Swift UI cannot yet handle multiple sheets
                    try? await Task.sleep(for: .milliseconds(100))
                    await MainActor.run {
                        switch finalResult {
                        case .thankYou:
                            donationPopUpState = .thankYou
                        case .error:
                            donationPopUpState = .error
                        }
                        showDonationPopUp = true
                    }
                }
            }
        }, content: {
            Group {
                switch donationPopUpState {
                case .selection:
                    PaymentForm(amountSelected: amountSelected)
                        .presentationDetents([.fraction(0.65)])
                case .selectedAmount(let selectedAmount):
                    PaymentSummary(selectedAmount: selectedAmount, onComplete: {
                        showDonationPopUp = false
                    })
                    .presentationDetents([.fraction(0.65)])
                case .thankYou:
                    PaymentResultPopUp(state: .thankYou)
                        .presentationDetents([.fraction(0.33)])
                case .error:
                    PaymentResultPopUp(state: .error)
                        .presentationDetents([.fraction(0.33)])
                }
            }
            .onReceive(amountSelected) { value in
                if let amount = value {
                    donationPopUpState = .selectedAmount(amount)
                } else {
                    donationPopUpState = .selection
                }
            }
        })
    }

    var readingSettings: some View {
        let isSnippet = Binding {
            switch searchResultSnippetMode {
            case .matches: return true
            case .disabled: return false
            }
        } set: { isOn in
            searchResultSnippetMode = isOn ? .matches : .disabled
        }
        return Section("reading_settings.tab.reading".localized) {
            Stepper(value: $webViewPageZoom, in: 0.5...2, step: 0.05) {
                Text("reading_settings.zoom.title".localized +
                     ": \(Formatter.percent.string(from: NSNumber(value: webViewPageZoom)) ?? "")")
            }
            if FeatureFlags.showExternalLinkOptionInSettings {
                Picker("reading_settings.external_link.title".localized, selection: $externalLinkLoadingPolicy) {
                    ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                        Text(loadingPolicy.name).tag(loadingPolicy)
                    }
                }
            }
            if FeatureFlags.showSearchSnippetInSettings {
                Toggle("reading_settings.search_snippet.title".localized, isOn: isSnippet)
            }
        }
    }

    var librarySettings: some View {
        Section {
            NavigationLink {
                LanguageSelector()
            } label: {
                SelectedLanaguageLabel()
            }.disabled(library.state != .complete)
            Toggle("library_settings.toggle.cellular".localized, isOn: $downloadUsingCellular)
            Toggle("library_settings.toggle.live_activities".localized, isOn: $enableLiveActivities)
        } header: {
            Text("library_settings.tab.library.title".localized)
        } footer: {
            Text("library_settings.new-download-task-description".localized)
        }
    }

    var catalogSettings: some View {
        Section {
            HStack {
                if library.state == .error {
                    Text("library_refresh_error.retrieve.description".localized).foregroundColor(.red)
                } else {
                    Text("catalog_settings.last_refresh.text".localized)
                    Spacer()
                    LibraryLastRefreshTime().foregroundColor(.secondary)
                }
            }
            if library.state == .inProgress {
                HStack {
                    Text("catalog_settings.refreshing.text".localized).foregroundColor(.secondary)
                    Spacer()
                    ProgressView().progressViewStyle(.circular)
                }
            } else {
                Button("catalog_settings.refresh_now.button".localized) {
                    library.start(isUserInitiated: true)
                }
            }
            Toggle("catalog_settings.auto_refresh.toggle".localized, isOn: $libraryAutoRefresh)
        } header: {
            Text("catalog_settings.header.text".localized)
        } footer: {
            Text("catalog_settings.footer.text".localized)
        }
    }

    var backupSettings: some View {
        Section {
            Toggle("backup_settings.toggle.title".localized, isOn: $backupDocumentDirectory)
        } header: {
            Text("backup_settings.header.text".localized)
        } footer: {
            Text("backup_settings.footer.text".localized)
        }.onChange(of: backupDocumentDirectory) { LibraryOperations.applyFileBackupSetting(isEnabled: $0) }
    }

    var miscellaneous: some View {
        Section("settings.miscellaneous.title".localized) {
            if Payment.paymentButtonType() != nil {
                SupportKiwixButton {
                    openDonation()
                }
            }
            Button("settings.miscellaneous.button.feedback".localized) {
                UIApplication.shared.open(URL(string: "mailto:feedback@kiwix.org")!)
            }
            Button("settings.miscellaneous.button.rate_app".localized) {
                let url = URL(appStoreReviewForName: Brand.appName.lowercased(),
                              appStoreID: Brand.appStoreId)
                UIApplication.shared.open(url)
            }
            NavigationLink("settings.miscellaneous.navigation.about".localized) { About() }
        }
    }
}

private struct SelectedLanaguageLabel: View {
    @Default(.libraryLanguageCodes) private var languageCodes

    var body: some View {
        HStack {
            Text("settings.selected_language.title".localized)
            Spacer()
            if languageCodes.count == 1,
               let languageCode = languageCodes.first,
                let languageName = Locale.current.localizedString(forLanguageCode: languageCode) {
                Text(languageName).foregroundColor(.secondary)
            } else if languageCodes.count > 1 {
                Text("\(languageCodes.count)").foregroundColor(.secondary)
            }
        }
    }
}
#endif
