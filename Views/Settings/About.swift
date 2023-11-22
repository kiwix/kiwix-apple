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
            SettingSection(name: "About".localized) {
                about
                ourWebsite
            }
            SettingSection(name: "Release".localized) {
                release
                HStack {
                    source
                    license
                }
            }
            SettingSection(name: "Dependencies".localized, alignment: .top) {
                Table(dependencies) {
                    TableColumn("Name".localized, value: \.name)
                    TableColumn("License".localized) { dependency in Text(dependency.license ?? "") }
                    TableColumn("Version".localized, value: \.version)
                }.tableStyle(.bordered(alternatesRowBackgrounds: true))
            }
        }
        .padding()
        .tabItem { Label("About".localized, systemImage: "info.circle") }
        .task { await getDependencies() }
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
            Section("Release".localized) {
                release
                appVersion
                buildNumber
                source
                license
            }
            Section("Dependencies".localized) {
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
        .navigationTitle("About".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $externalLinkURL) { SafariView(url: $0) }
        .task { await getDependencies() }
        #endif
    }
    
    private var about: some View {
        Text("loc-About-description".localized)
    }
    
    private var release: some View {
        Text("This app is released under the terms of the GNU General Public License version 3.".localized)
    }
    
    private var appVersion: some View {
        Attribute(title: "Version".localized, 
                  detail: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
    }
    
    private var buildNumber: some View {
        Attribute(title: "Build".localized, detail: Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
    }
    
    private var ourWebsite: some View {
        Button("Our Website".localized) {
            externalLinkURL = URL(string: "https://www.kiwix.org")
        }
    }
    
    private var source: some View {
        Button("Source".localized) {
            externalLinkURL = URL(string: "https://github.com/kiwix/apple")
        }
    }
    
    private var license: some View {
        Button("GNU General Public License v3".localized) {
            externalLinkURL = URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")
        }
    }
    
    private func getDependencies() async {
        dependencies = kiwix.getVersions().map { datum in
            Dependency(name: String(datum.first), version: String(datum.second))
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

#Preview {
    #if os(macOS)
    TabView { About() }
    #elseif os(iOS)
    NavigationView { About() }
    #endif
}
