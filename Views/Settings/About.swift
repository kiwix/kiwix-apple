//
//  About.swift
//  Kiwix
//
//  Created by Chris Li on 6/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import CoreKiwix

struct About: View {
    @State private var dependencies = [Dependency]()
    @State private var externalLinkURL: URL?
    
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
            SettingSection(name: "Dependencies", alignment: .top) {
                Table(dependencies) {
                    TableColumn("Name", value: \.name)
                    TableColumn("License", value: \.license)
                    TableColumn("Version") { dependency in Text(dependency.version ?? "") }
                }.tableStyle(.bordered(alternatesRowBackgrounds: true))
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
            Section("Release") {
                release
                appVersion
                buildNumber
                source
                license
            }
            Section("Dependencies") {
                ForEach(dependencies) { dependency in
                    HStack {
                        Text(dependency.name)
                        Spacer()
                        if let license = dependency.license {
                            Text("\(license) (\(dependency.version))").foregroundColor(.secondary)
                        } else {
                            Text(dependency.version).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $externalLinkURL) {
            SafariView(url: $0)
        }
        .task {
            dependencies = kiwix.getVersions().map { datum in
                Dependency(name: String(datum.first), version: String(datum.second))
            }
        }
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
    
    var appVersion: some View {
        HStack {
            Text("Version")
            Spacer()
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text(version).foregroundColor(.secondary)
            }
        }
    }
    
    var buildNumber: some View {
        HStack {
            Text("Build")
            Spacer()
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text(build).foregroundColor(.secondary)
            }
        }
    }
    
    var ourWebsite: some View {
        Button("Our Website") {
            externalLinkURL = URL(string: "https://www.kiwix.org")
        }
    }
    
    var source: some View {
        Button("Source") {
            externalLinkURL = URL(string: "https://github.com/kiwix/apple")
        }
    }
    
    var license: some View {
        Button("GNU General Public License v3") {
            externalLinkURL = URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")
        }
    }
}

private struct Dependency: Identifiable {
    var id: String { name }
    
    let name: String
    let version: String
    
    
    var license: String? {
        switch name {
        case "libkiwix":
            "GPLv3"
        case "libzim":
            "GPLv2"
        case "libxapian":
            "GPLv2"
        case "libicu":
            "ICU"
        default:
            nil
        }
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
