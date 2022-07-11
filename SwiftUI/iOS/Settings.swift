//
//  Settings.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 6/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct Settings: View {
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
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
            }
            LibrarySettings()
            Section {
                Toggle("Include zim files in backup", isOn: $backupDocumentDirectory)
            } header: {
                Text("Backup")
            } footer: {
                Text("Does not apply to files opened in place.")
            }
            NavigationLink("About") { About() }
        }
        .navigationTitle("Settings")
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
