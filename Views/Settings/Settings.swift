// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI
import Defaults

enum PortNumberFormatter {
    static let instance: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        return formatter
    }()
}

#if os(macOS)
struct ReadingSettings: View {
    @EnvironmentObject private var colorSchemeStore: UserColorSchemeStore
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
            SettingSection(name: LocalString.reading_settings_zoom_title) {
                HStack {
                    Stepper(webViewPageZoom.formatted(.percent), value: $webViewPageZoom, in: 0.5...2, step: 0.05)
                    Spacer()
                    Button(LocalString.reading_settings_zoom_reset_button) {
                        webViewPageZoom = 1
                    }.disabled(webViewPageZoom == 1)
                }
            }
            if FeatureFlags.showExternalLinkOptionInSettings {
                SettingSection(name: LocalString.reading_settings_external_link_title) {
                    Picker(selection: $externalLinkLoadingPolicy) {
                        ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                            Text(loadingPolicy.name).tag(loadingPolicy)
                        }
                    } label: { }
                }
            }
            // Theme
            SettingSection(name: LocalString.theme_settings_title) {
                Picker(selection: $colorSchemeStore.userColorScheme) {
                    ForEach(UserColorScheme.allCases) { colorScheme in
                        Text(colorScheme.name).tag(colorScheme)
                    }
                } label: { }
            }
            
            if FeatureFlags.showSearchSnippetInSettings {
                SettingSection(name: LocalString.reading_settings_search_snippet_title) {
                    Toggle(" ", isOn: isSnippet)
                }
            }
            Spacer()
        }
        .padding()
        .tabItem { Label(LocalString.reading_settings_tab_reading, systemImage: "book") }
    }
}

struct LibrarySettings: View {
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @EnvironmentObject private var library: LibraryViewModel

    var body: some View {
        VStack(spacing: 16) {
            SettingSection(name: LocalString.library_settings_catalog_title, alignment: .top) {
                HStack(spacing: 6) {
                    Button(LocalString.library_settings_button_refresh_now) {
                        library.start(isUserInitiated: true)
                    }.disabled(library.state == .inProgress)
                    if library.state == .inProgress {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                    }
                    Spacer()
                    if library.state == .error {
                        Text(LocalString.library_refresh_error_retrieve_description).foregroundColor(.red)
                    } else {
                        Text(LocalString.library_settings_last_refresh_text + ":").foregroundColor(.secondary)
                        LibraryLastRefreshTime().foregroundColor(.secondary)
                    }

                }
                VStack(alignment: .leading) {
                    Toggle(LocalString.library_settings_auto_refresh_toggle, isOn: $libraryAutoRefresh)
                    Text(LocalString.library_settings_catalog_warning_text)
                        .foregroundColor(.secondary)
                }
            }
            SettingSection(name: LocalString.library_settings_languages_title, alignment: .top) {
                LanguageSelector()
                    .environmentObject(library)
            }
        }
        .padding()
        .tabItem { Label(LocalString.library_settings_catalog_title, systemImage: "folder.badge.gearshape") }
    }
}

struct HotspotSettings: View {
    
    @State private var portNumber: Int
    @Environment(\.controlActiveState) var controlActiveState
    
    init() {
        self.portNumber = Defaults[.hotspotPortNumber]
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingSection(name: LocalString.hotspot_settings_port_number) {
                // on macOS we can always focus on the port input
                // regardless if we come from default settings route
                // or being deeplinked from Hotspot error
                PortInput(focusOnPortInput: true)
                Text(Hotspot.validPortRangeMessage())
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .tabItem { Label(LocalString.enum_navigation_item_hotspot, systemImage: "wifi") }
    }
}

#elseif os(iOS)

import PassKit
import Combine

struct Settings: View {

    let scrollToHotspot: Bool
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom
    @EnvironmentObject private var colorSchemeStore: UserColorSchemeStore
    @EnvironmentObject private var library: LibraryViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    enum Route {
        case languageSelector, about
    }
    
    func openDonation() {
        NotificationCenter.openDonations()
    }

    var body: some View {
        Group {
            if FeatureFlags.hasLibrary {
                ScrollViewReader { proxy in
                    List {
                        readingSettings
                        downloadSettings
                        catalogSettings
                        miscellaneous
                        hotspot.id("hotspot")
                        backupSettings
                    }
                    .modifier(ToolbarRoleBrowser())
                    .navigationTitle(LocalString.settings_navigation_title)
                    .task {
                        if scrollToHotspot {
                            proxy.scrollTo("hotspot", anchor: .top)
                        }
                    }
                }
            } else {
                List {
                    readingSettings
                    miscellaneous
                }
                .modifier(ToolbarRoleBrowser())
                .navigationTitle(LocalString.settings_navigation_title)
            }
        }
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
        return Section(LocalString.reading_settings_tab_reading) {
            // Theme
            Picker(LocalString.theme_settings_title, selection: $colorSchemeStore.userColorScheme) {
                ForEach(UserColorScheme.allCases) { colorScheme in
                    Text(colorScheme.name).tag(colorScheme)
                }
            }
            
            Stepper(value: $webViewPageZoom, in: 0.5...2, step: 0.05) {
                Text(LocalString.reading_settings_zoom_title +
                     ": \(Formatter.percent.string(from: NSNumber(value: webViewPageZoom)) ?? "")")
            }
            if FeatureFlags.showExternalLinkOptionInSettings {
                Picker(LocalString.reading_settings_external_link_title, selection: $externalLinkLoadingPolicy) {
                    ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                        Text(loadingPolicy.name).tag(loadingPolicy)
                    }
                }
            }
            if FeatureFlags.showSearchSnippetInSettings {
                Toggle(LocalString.reading_settings_search_snippet_title, isOn: isSnippet)
            }
        }
    }

    var downloadSettings: some View {
        Section {
            Toggle(LocalString.library_settings_toggle_cellular, isOn: $downloadUsingCellular)
        } header: {
            Text(LocalString.library_settings_downloads_title)
        } footer: {
            Text(LocalString.library_settings_new_download_task_description)
        }
    }

    var catalogSettings: some View {
        Section {
            NavigationLink {
                LanguageSelector()
            } label: {
                SelectedLanaguageLabel()
            }.disabled(library.state != .complete)
            HStack {
                if library.state == .error {
                    Text(LocalString.library_refresh_error_retrieve_description).foregroundColor(.red)
                } else {
                    Text(LocalString.catalog_settings_last_refresh_text)
                    Spacer()
                    LibraryLastRefreshTime().foregroundColor(.secondary)
                }
            }
            if library.state == .inProgress {
                HStack {
                    Text(LocalString.catalog_settings_refreshing_text).foregroundColor(.secondary)
                    Spacer()
                    ProgressView().progressViewStyle(.circular)
                }
            } else {
                Button(LocalString.catalog_settings_refresh_now_button) {
                    library.start(isUserInitiated: true)
                }
            }
            Toggle(LocalString.catalog_settings_auto_refresh_toggle, isOn: $libraryAutoRefresh)
        } header: {
            Text(LocalString.catalog_settings_header_text)
        } footer: {
            Text(LocalString.catalog_settings_footer_text)
        }
    }

    var backupSettings: some View {
        Section {
            Toggle(LocalString.backup_settings_toggle_title, isOn: $backupDocumentDirectory)
        } header: {
            Text(LocalString.backup_settings_header_text)
        } footer: {
            Text(LocalString.backup_settings_footer_text)
        }.onChange(of: backupDocumentDirectory) { LibraryOperations.applyFileBackupSetting(isEnabled: $0) }
    }

    var miscellaneous: some View {
        Section(LocalString.settings_miscellaneous_title) {
            if Payment.paymentButtonType() != nil, horizontalSizeClass != .regular {
                SupportKiwixButton {
                    openDonation()
                }
            }
            Button(LocalString.settings_miscellaneous_button_feedback) {
                UIApplication.shared.open(URL(string: "mailto:feedback@kiwix.org")!)
            }
            Button("Report an bug") {
                if let logStore = try? OSLogStore(scope: .currentProcessIdentifier),
                   let entries = try? logStore.getEntries() {
                    for entry in enties {
                        print(entry)
                    }
                } else {
                    print("couldn't collect logs")
                }
            }
            Button(LocalString.settings_miscellaneous_button_rate_app) {
                let url = URL(appStoreReviewForName: Brand.appName.lowercased(),
                              appStoreID: Brand.appStoreId)
                UIApplication.shared.open(url)
            }
            NavigationLink(LocalString.settings_miscellaneous_navigation_about) { About() }
        }
    }
    
    var hotspot: some View {
        Section {
            PortInput(focusOnPortInput: scrollToHotspot)
        } header: {
            Text(LocalString.enum_navigation_item_hotspot)
        } footer: {
            Text(Hotspot.validPortRangeMessage())
        }
    }
}

private struct SelectedLanaguageLabel: View {
    @Default(.libraryLanguageCodes) private var languageCodes

    var body: some View {
        HStack {
            Text(LocalString.settings_selected_language_title)
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
