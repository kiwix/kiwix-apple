//
//  Settings.swift
//  Kiwix
//
//  Created by Chris Li on 6/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

#if os(macOS)
struct SettingSection<Content: View>: View {
    let name: String
    var content: () -> Content
    
    init(name: String, @ViewBuilder content: @escaping () -> Content) {
        self.name = name
        self.content = content
    }
    
    var body: some View {
        HStack(alignment :.top) {
            Text("\(name):").frame(width: 100, alignment: .trailing)
            VStack(alignment: .leading, spacing: 16, content: content)
            Spacer()
        }
    }
}
#elseif os(iOS)
struct Settings: View {
    @Default(.webViewPageZoom) var webViewPageZoom
    @Default(.externalLinkLoadingPolicy) var externalLinkLoadingPolicy
    @Default(.searchResultSnippetMode) var searchResultSnippetMode
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Stepper(value: $webViewPageZoom, in: 0...2, step: 0.1) {
                        Text("Page zoom: \(webViewPageZoom)")
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
                    NavigationLink("Library") { LibrarySettings() }
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
#endif
