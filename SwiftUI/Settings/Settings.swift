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
    @Default(.webViewPageZoom) var webViewPageZoom
    @Default(.externalLinkLoadingPolicy) var externalLinkLoadingPolicy
    @Default(.searchResultSnippetMode) var searchResultSnippetMode
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        NavigationView {
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
                LibrarySettings()
                Section {
                    Toggle("Include zim files in backup", isOn: $backupDocumentDirectory)
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Does not apply to files opened in place.")
                }
                Section {
                    NavigationLink("About") { About() }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
