//
//  Settings.swift
//  Kiwix
//
//  Created by Chris Li on 10/1/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

#if os(macOS)
struct ReadingSettings: View {
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom
    
    var body: some View {
        VStack(spacing: 16) {
            SettingSection(name: "title_page_zoom".localized) {
                HStack {
                    Stepper(webViewPageZoom.formatted(.percent), value: $webViewPageZoom, in: 0.5...2, step: 0.05)
                    Spacer()
                    Button("title_reset".localized) { webViewPageZoom = 1 }.disabled(webViewPageZoom == 1)
                }
            }
            if FeatureFlags.showExternalLinkOptionInSettings {
                SettingSection(name: "external_link_handler.alert.title".localized) {
                    Picker(selection: $externalLinkLoadingPolicy) {
                        ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                            Text(loadingPolicy.name.localized).tag(loadingPolicy)
                        }
                    } label: { }
                }
            }
            if FeatureFlags.showSearchSnippetInSettings {
                SettingSection(name: "reading_settings.search_snippet.title".localized) {
                    Picker(selection: $searchResultSnippetMode) {
                        ForEach(SearchResultSnippetMode.allCases) { snippetMode in
                            Text(snippetMode.name.localized).tag(snippetMode)
                        }
                    } label: { }
                }
            }
        }
        .padding()
        .tabItem { Label("title_reading".localized, systemImage: "book") }
    }
}

struct LibrarySettings: View {
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @EnvironmentObject private var library: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            SettingSection(name: "title_catalog".localized) {
                HStack(spacing: 6) {
                    Button("title_refresh_now".localized) {
                        library.start(isUserInitiated: true)
                    }.disabled(library.isInProgress)
                    if library.isInProgress {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                    }
                    Spacer()
                    Text("title_last_refresh".localized + ":").foregroundColor(.secondary)
                    LibraryLastRefreshTime().foregroundColor(.secondary)
                }
                VStack(alignment: .leading) {
                    Toggle("title_auto_refresh".localized, isOn: $libraryAutoRefresh)
                    Text("settings_catalog_warning".localized)
                        .foregroundColor(.secondary)
                }
            }
            SettingSection(name: "title-languages".localized, alignment: .top) {
                LanguageSelector()
            }
        }
        .padding()
        .tabItem { Label("button-tab-library".localized, systemImage: "folder.badge.gearshape") }
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

struct Settings: View {
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom
    @EnvironmentObject private var library: LibraryViewModel
    
    enum Route {
        case languageSelector, about
    }
    
    var body: some View {
        if FeatureFlags.hasLibrary {
            List {
                readingSettings
                librarySettings
                catalogSettings
                backupSettings
                miscellaneous
            }
            .modifier(ToolbarRoleBrowser())
            .navigationTitle("Settings".localized)
        } else {
            List {
                readingSettings
                miscellaneous
            }
            .modifier(ToolbarRoleBrowser())
            .navigationTitle("Settings".localized)
        }
    }
    
    var readingSettings: some View {
        Section("title_reading".localized) {
            Stepper(value: $webViewPageZoom, in: 0.5...2, step: 0.05) {
                Text("title_page_zoom".localized +
                     ": \(Formatter.percent.string(from: NSNumber(value: webViewPageZoom)) ?? "")")
            }
            if FeatureFlags.showExternalLinkOptionInSettings {
                Picker("alert-external-link".localized, selection: $externalLinkLoadingPolicy) {
                    ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                        Text(loadingPolicy.name.localized).tag(loadingPolicy)
                    }
                }
            }
            if FeatureFlags.showSearchSnippetInSettings {
                Picker("title_search_snippet".localized, selection: $searchResultSnippetMode) {
                    ForEach(SearchResultSnippetMode.allCases) { snippetMode in
                        Text(snippetMode.name.localized).tag(snippetMode)
                    }
                }
            }
        }
    }
    
    var librarySettings: some View {
        Section {
            NavigationLink {
                LanguageSelector()
            } label: {
                SelectedLanaguageLabel()
            }
            Toggle("toggle-cellular".localized, isOn: $downloadUsingCellular)
        } header: {
            Text("button-tab-library".localized)
        } footer: {
            Text("settings-new-download-task-description".localized)
        }
    }
    
    var catalogSettings: some View {
        Section {
            HStack {
                Text("title_last_refresh".localized)
                Spacer()
                LibraryLastRefreshTime().foregroundColor(.secondary)
            }
            if library.isInProgress {
                HStack {
                    Text("title-refreshing".localized).foregroundColor(.secondary)
                    Spacer()
                    ProgressView().progressViewStyle(.circular)
                }
            } else {
                Button("title_refresh_now".localized) {
                    library.start(isUserInitiated: true)
                }
            }
            Toggle("title_auto_refresh".localized, isOn: $libraryAutoRefresh)
        } header: {
            Text("title_catalog".localized)
        } footer: {
            Text("settings_catalog_warning".localized)
        }.onChange(of: libraryAutoRefresh) { LibraryOperations.applyLibraryAutoRefreshSetting(isEnabled: $0) }
    }
    
    var backupSettings: some View {
        Section {
            Toggle("settings-zim-file-backup".localized, isOn: $backupDocumentDirectory)
        } header: {
            Text("title-backup".localized)
        } footer: {
            Text("settings-no-apply".localized)
        }.onChange(of: backupDocumentDirectory) { LibraryOperations.applyFileBackupSetting(isEnabled: $0) }
    }
    
    var miscellaneous: some View {
        Section("title-misc".localized) {
            Button("title-feedback".localized) { UIApplication.shared.open(URL(string: "mailto:feedback@kiwix.org")!) }
            Button("title-rate-app".localized) {
                let url = URL(appStoreReviewForName: Brand.appName.lowercased(),
                              appStoreID: Brand.appStoreId)
                UIApplication.shared.open(url)
            }
            NavigationLink("title-about".localized) { About() }
        }
    }
}

private struct SelectedLanaguageLabel: View {
    @Default(.libraryLanguageCodes) private var languageCodes
    
    var body: some View {
        HStack {
            Text("title-languages".localized)
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
