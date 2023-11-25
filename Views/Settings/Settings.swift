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
            SettingSection(name: "Page zoom".localized) {
                HStack {
                    Stepper(webViewPageZoom.formatted(.percent), value: $webViewPageZoom, in: 0.5...2, step: 0.05)
                    Spacer()
                    Button("Reset".localized) { webViewPageZoom = 1 }.disabled(webViewPageZoom == 1)
                }
            }
            SettingSection(name: "External link".localized) {
                Picker(selection: $externalLinkLoadingPolicy) {
                    ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                        Text(loadingPolicy.name.localized).tag(loadingPolicy)
                    }
                } label: { }
            }
            SettingSection(name: "Search snippet".localized) {
                Picker(selection: $searchResultSnippetMode) {
                    ForEach(SearchResultSnippetMode.allCases) { snippetMode in
                        Text(snippetMode.name.localized).tag(snippetMode)
                    }
                } label: { }
            }
        }
        .padding()
        .tabItem { Label("Reading".localized, systemImage: "book") }
    }
}

struct LibrarySettings: View {
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @EnvironmentObject private var library: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            SettingSection(name: "Catalog".localized) {
                HStack(spacing: 6) {
                    Button("Refresh Now".localized) {
                        library.start(isUserInitiated: true)
                    }.disabled(library.isInProgress)
                    if library.isInProgress {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                    }
                    Spacer()
                    Text("Last refresh".localized + ":").foregroundColor(.secondary)
                    LibraryLastRefreshTime().foregroundColor(.secondary)
                }
                VStack(alignment: .leading) {
                    Toggle("Auto refresh".localized, isOn: $libraryAutoRefresh)
                    Text("When enabled, the library catalog will be refreshed automatically when outdated.".localized)
                        .foregroundColor(.secondary)
                }
            }
            SettingSection(name: "Languages".localized, alignment: .top) {
                LanguageSelector()
            }
        }
        .padding()
        .tabItem { Label("Library".localized, systemImage: "folder.badge.gearshape") }
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
        Section("Reading".localized) {
            Stepper(value: $webViewPageZoom, in: 0.5...2, step: 0.05) {
                Text("Page zoom".localized + 
                     ": \(Formatter.percent.string(from: NSNumber(value: webViewPageZoom)) ?? "")")
            }
            Picker("External link".localized, selection: $externalLinkLoadingPolicy) {
                ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                    Text(loadingPolicy.name.localized).tag(loadingPolicy)
                }
            }
            Picker("Search snippet".localized, selection: $searchResultSnippetMode) {
                ForEach(SearchResultSnippetMode.allCases) { snippetMode in
                    Text(snippetMode.name.localized).tag(snippetMode)
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
            Toggle("Download using cellular".localized, isOn: $downloadUsingCellular)
        } header: {
            Text("Library".localized)
        } footer: {
            Text("Change will only apply to new download tasks.".localized)
        }
    }
    
    var catalogSettings: some View {
        Section {
            HStack {
                Text("Last refresh".localized)
                Spacer()
                LibraryLastRefreshTime().foregroundColor(.secondary)
            }
            if library.isInProgress {
                HStack {
                    Text("Refreshing...".localized).foregroundColor(.secondary)
                    Spacer()
                    ProgressView().progressViewStyle(.circular)
                }
            } else {
                Button("Refresh Now".localized) {
                    library.start(isUserInitiated: true)
                }
            }
            Toggle("Auto refresh".localized, isOn: $libraryAutoRefresh)
        } header: {
            Text("Catalog".localized)
        } footer: {
            Text("When enabled, the library catalog will be refreshed automatically when outdated.".localized)
        }.onChange(of: libraryAutoRefresh) { LibraryOperations.applyLibraryAutoRefreshSetting(isEnabled: $0) }
    }
    
    var backupSettings: some View {
        Section {
            Toggle("Include zim files in backup".localized, isOn: $backupDocumentDirectory)
        } header: {
            Text("Backup".localized)
        } footer: {
            Text("Does not apply to files opened in place.".localized)
        }.onChange(of: backupDocumentDirectory) { LibraryOperations.applyFileBackupSetting(isEnabled: $0) }
    }
    
    var miscellaneous: some View {
        Section("Misc".localized) {
            Button("Feedback".localized) { UIApplication.shared.open(URL(string: "mailto:feedback@kiwix.org")!) }
            Button("Rate the App".localized) {
                let url = URL(string: "itms-apps://itunes.apple.com/us/app/kiwix/id997079563?action=write-review")!
                UIApplication.shared.open(url)
            }
            NavigationLink("About".localized) { About() }
        }
    }
}

private struct SelectedLanaguageLabel: View {
    @Default(.libraryLanguageCodes) private var languageCodes
    
    var body: some View {
        HStack {
            Text("Languages".localized)
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
