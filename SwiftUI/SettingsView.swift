//
//  SettingsView.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 6/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import BackgroundTasks
import SwiftUI

import Defaults

struct SettingsView: View {
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @Default(.libraryLanguageCodes) private var libraryLanguageCodes
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        Form {
            Section {
                Stepper(value: $webViewPageZoom, in: 0.5...1.5, step: 0.05) {
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
            } header: { Text("Reading") }
            Section {
                NavigationLink {
                    LanguageSelector()
                } label: {
                    HStack {
                        Text("Languages")
                        Spacer()
                        if libraryLanguageCodes.count == 1,
                           let languageCode = libraryLanguageCodes.first,
                            let languageName = Locale.current.localizedString(forLanguageCode: languageCode) {
                            Text(languageName).foregroundColor(.secondary)
                        } else if libraryLanguageCodes.count > 1 {
                            Text("\(libraryLanguageCodes.count)").foregroundColor(.secondary)
                        }
                    }
                }
                Toggle("Download using cellular", isOn: $downloadUsingCellular)
            } header: {
                Text("Library")
            } footer: {
                Text("Change will only apply to new download tasks.")
            }
            Section {
                HStack {
                    Text("Last refresh")
                    Spacer()
                    LibraryLastRefreshTime().foregroundColor(.secondary)
                }
                if viewModel.isRefreshing {
                    HStack {
                        Text("Refreshing...").foregroundColor(.secondary)
                        Spacer()
                        ProgressView().progressViewStyle(.circular)
                    }
                } else {
                    Button("Refresh Now") {
                        Task { viewModel.startRefresh(isUserInitiated: true) }
                    }
                }
                Toggle("Auto refresh", isOn: $libraryAutoRefresh)
            } header: {
                Text("Catalog")
            } footer: {
                Text("When enabled, the library catalog will be refreshed automatically when outdated.")
            }
            Section {
                Toggle("Include zim files in backup", isOn: $backupDocumentDirectory)
            } header: {
                Text("Backup")
            } footer: {
                Text("Does not apply to files opened in place.")
            }
            Section {
                Button("Feedback") { UIApplication.shared.open(URL(string: "mailto:feedback@kiwix.org")!) }
                Button("Rate the App") {
                    let url = URL(string:"itms-apps://itunes.apple.com/us/app/kiwix/id997079563?action=write-review")!
                    UIApplication.shared.open(url)
                }
                NavigationLink("About") { About() }
            } header: {
                Text("Misc")
            }
        }
        .navigationTitle("Settings")
        .onChange(of: libraryAutoRefresh) { SettingsView.applyLibraryAutoRefreshSetting(isEnabled: $0) }
        .onChange(of: backupDocumentDirectory) { SettingsView.applyFileBackupSetting(isEnabled: $0) }
    }
    
    static func applyLibraryAutoRefreshSetting(isEnabled: Bool? = nil) {
        if isEnabled ?? Defaults[.libraryAutoRefresh] {
            let request = BGAppRefreshTaskRequest(identifier: LibraryViewModel.backgroundTaskIdentifier)
            try? BGTaskScheduler.shared.submit(request)
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: LibraryViewModel.backgroundTaskIdentifier)
        }
    }
    
    static func applyFileBackupSetting(isEnabled: Bool? = nil) {
        do {
            let directory = try FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
            )
            let urls = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isExcludedFromBackupKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
            ).filter({ $0.pathExtension.contains("zim") })
            let backupDocumentDirectory = isEnabled ?? Defaults[.backupDocumentDirectory]
            try urls.forEach { url in
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = !backupDocumentDirectory
                var url = url
                try url.setResourceValues(resourceValues)
            }
            print(
                """
                Applying zim file backup setting (\(backupDocumentDirectory ? "backing up" : "not backing up")) \
                on \(urls.count) zim file(s)
                """
            )
        } catch {}
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
