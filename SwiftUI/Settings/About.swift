//
//  About.swift
//  Kiwix
//
//  Created by Chris Li on 6/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct About: View {
    @State private var externalLinkURL: URL?
    
    private let dependencies = [
        Dependency(name: "libkiwix", license: "GPLv3", version: "9.4.1"),
        Dependency(name: "libzim", license: "GPLv2", version: "6.3.2"),
        Dependency(name: "Xapian", license: "GPLv2", version: nil),
        Dependency(name: "ICU", license: "ICU", version: nil),
        Dependency(name: "Defaults", license: "MIT", version: "6.3.0"),
        Dependency(name: "Fuzi", license: "MIT", version: "3.1.3")
    ]
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            SettingSection(name: "About") {
                about
                ourWebsite
            }
            SettingSection(name: "Release") {
                release
                HStack {
                    source
                    license
                }
            }
            SettingSection(name: "Dependencies") {
                Table(dependencies) {
                    TableColumn("Name", value: \.name)
                    TableColumn("License", value: \.license)
                    TableColumn("Version") { dependency in Text(dependency.version ?? "") }
                }
            }
        }
        .padding()
        .tabItem { Label("About", systemImage: "info.circle") }
        .onChange(of: externalLinkURL) { url in
            guard let url = url else { return }
            NSWorkspace.shared.open(url)
        }
        #elseif os(iOS)
        List {
            Section {
                about
                ourWebsite
            }
            Section {
                release
                source
                license
            } header: { Text("Release") }
            Section {
                ForEach(dependencies) { dependency in
                    HStack {
                        Text(dependency.name)
                        Spacer()
                        Text(dependency.license).foregroundColor(.secondary)
                        if let version = dependency.version {
                            Text("(\(version))").foregroundColor(.secondary)
                        }
                    }
                }
            } header: { Text("Dependencies") }
        }
        .navigationTitle("About")
        .sheet(item: $externalLinkURL) { SafariView(url: $0).ignoresSafeArea(.container, edges: .all) }
        #endif
    }
    
    var about: some View {
        Text(
             """
             Kiwix is an offline reader for online content like Wikipedia, Project Gutenberg, or TED Talks. \
             It makes knowledge available to people with no or limited internet access. \
             The software as well as the content is free to use for anyone.
             """
        )
        .lineLimit(nil)
        .minimumScaleFactor(0.5) // to avoid unnecessary truncation (three dots)
    }
    
    var release: some View {
        Text("This app is released under the terms of the GNU General Public License version 3.")
    }
    
    var ourWebsite: some View {
        Button("Our Website") { externalLinkURL = URL(string: "https://www.kiwix.org") }
    }
    
    var source: some View {
        Button("Source") { externalLinkURL = URL(string: "https://github.com/kiwix/apple") }
    }
    
    var license: some View {
        Button("GNU General Public License v3") {
            externalLinkURL = URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")
        }
    }
    
    struct Dependency: Identifiable {
        var id: String { name }
        
        let name: String
        let license: String
        let version: String?
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        TabView { About() }.preferredColorScheme(.light)
        TabView { About() }.preferredColorScheme(.dark)
        #elseif os(iOS)
        NavigationView { About() }
        #endif
    }
}
