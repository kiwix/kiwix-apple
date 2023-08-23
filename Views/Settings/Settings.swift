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
            SettingSection(name: "Page zoom") {
                HStack {
                    Stepper(webViewPageZoom.formatted(.percent), value: $webViewPageZoom, in: 0.5...2, step: 0.05)
                    Spacer()
                    Button("Reset") { webViewPageZoom = 1 }.disabled(webViewPageZoom == 1)
                }
            }
            SettingSection(name: "External link") {
                Picker(selection: $externalLinkLoadingPolicy) {
                    ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                        Text(loadingPolicy.name).tag(loadingPolicy)
                    }
                } label: { }
            }
            SettingSection(name: "Search snippet") {
                Picker(selection: $searchResultSnippetMode) {
                    ForEach(SearchResultSnippetMode.allCases) { snippetMode in
                        Text(snippetMode.name).tag(snippetMode)
                    }
                } label: { }
            }
        }
        .padding()
        .tabItem { Label("Reading", systemImage: "book") }
    }
}

struct LibrarySettings: View {
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @EnvironmentObject private var library: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            SettingSection(name: "Catalog") {
                HStack(spacing: 6) {
                    Button("Refresh Now") {
                        library.start(isUserInitiated: true)
                    }.disabled(library.isInProgress)
                    if library.isInProgress {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                    }
                    Spacer()
                    Text("Last refresh:").foregroundColor(.secondary)
                    LibraryLastRefreshTime().foregroundColor(.secondary)
                }
                VStack(alignment: .leading) {
                    Toggle("Auto refresh", isOn: $libraryAutoRefresh)
                    Text("When enabled, the library catalog will be refreshed automatically when outdated.")
                        .foregroundColor(.secondary)
                }
            }
            SettingSection(name: "Languages", alignment: .top) {
                LanguageSelector()
            }
        }
        .padding()
        .tabItem { Label("Library", systemImage: "folder.badge.gearshape") }
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
        List {
            readingSettings
            librarySettings
            catalogSettings
            backupSettings
            miscellaneous
        }
        .navigationTitle("Settings")
        .modify { view in
            if #available(iOS 16.0, *) {
                view.navigationDestination(for: Route.self) { route in
                    switch route {
                    case .languageSelector:
                        LanguageSelector()
                    case .about:
                        About()
                    }
                }
            } else {
                view
            }
        }
    }
    
    var readingSettings: some View {
        Section("Reading") {
            Stepper(value: $webViewPageZoom, in: 0.5...2, step: 0.05) {
                Text("Page zoom: \(Formatter.percent.string(from: NSNumber(value: webViewPageZoom)) ?? "")")
            }
            Picker("External link", selection: $externalLinkLoadingPolicy) {
                ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                    Text(loadingPolicy.name).tag(loadingPolicy)
                }
            }
            Picker("Search snippet", selection: $searchResultSnippetMode) {
                ForEach(SearchResultSnippetMode.allCases) { snippetMode in
                    Text(snippetMode.name).tag(snippetMode)
                }
            }
        }
    }
    
    var librarySettings: some View {
        Section {
            if #available(iOS 16.0, *) {
                NavigationLink(value: Route.languageSelector) {
                    SelectedLanaguageLabel()
                }
            } else {
                NavigationLink {
                    LanguageSelector()
                } label: {
                    SelectedLanaguageLabel()
                }
            }
            Toggle("Download using cellular", isOn: $downloadUsingCellular)
        } header: {
            Text("Library")
        } footer: {
            Text("Change will only apply to new download tasks.")
        }
    }
    
    var catalogSettings: some View {
        Section {
            HStack {
                Text("Last refresh")
                Spacer()
                LibraryLastRefreshTime().foregroundColor(.secondary)
            }
            if library.isInProgress {
                HStack {
                    Text("Refreshing...").foregroundColor(.secondary)
                    Spacer()
                    ProgressView().progressViewStyle(.circular)
                }
            } else {
                Button("Refresh Now") {
                    library.start(isUserInitiated: true)
                }
            }
            Toggle("Auto refresh", isOn: $libraryAutoRefresh)
        } header: {
            Text("Catalog")
        } footer: {
            Text("When enabled, the library catalog will be refreshed automatically when outdated.")
        }.onChange(of: libraryAutoRefresh) { LibraryOperations.applyLibraryAutoRefreshSetting(isEnabled: $0) }
    }
    
    var backupSettings: some View {
        Section {
            Toggle("Include zim files in backup", isOn: $backupDocumentDirectory)
        } header: {
            Text("Backup")
        } footer: {
            Text("Does not apply to files opened in place.")
        }.onChange(of: backupDocumentDirectory) { LibraryOperations.applyFileBackupSetting(isEnabled: $0) }
    }
    
    var miscellaneous: some View {
        Section("Misc") {
            Button("Feedback") { UIApplication.shared.open(URL(string: "mailto:feedback@kiwix.org")!) }
            Button("Rate the App") {
                let url = URL(string:"itms-apps://itunes.apple.com/us/app/kiwix/id997079563?action=write-review")!
                UIApplication.shared.open(url)
            }
            if #available(iOS 16.0, *) {
                NavigationLink("About", value: Route.about)
            } else {
                NavigationLink("About") { About() }
            }
        }
    }
}

private struct SelectedLanaguageLabel: View {
    @Default(.libraryLanguageCodes) private var languageCodes
    
    var body: some View {
        HStack {
            Text("Languages")
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
