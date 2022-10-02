//
//  ReadingSettings.swift
//  Kiwix
//
//  Created by Chris Li on 10/1/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct ReadingSettings: View {
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            SettingSection(name: "Page zoom") {
                HStack {
                    Stepper(value: $webViewPageZoom, in: 0.5...2, step: 0.05) {
                        Text("\(Formatter.percent.string(from: NSNumber(value: webViewPageZoom)) ?? "")")
                    }
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
        #elseif os(iOS)
        Section {
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
        } header: { Text("Reading") }
        #endif
    }
}

struct ReadingSettings_Previews: PreviewProvider {
    static var previews: some View {
        ReadingSettings()
    }
}
