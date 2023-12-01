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
            SettingSection(name: "title-about".localized) {
                about
                ourWebsite
            }
            SettingSection(name: "title-release".localized) {
                release
                HStack {
                    source
                    license
                }
            }
            SettingSection(name: "title-dependencies".localized, alignment: .top) {
                Table(dependencies) {
                    TableColumn("title-new".localized, value: \.name)
                    TableColumn("title-license".localized) { dependency in Text(dependency.license ?? "") }
                    TableColumn("title-version".localized, value: \.version)
                }.tableStyle(.bordered(alternatesRowBackgrounds: true))
            }
        }
        .padding()
        .tabItem { Label("title-about".localized, systemImage: "info.circle") }
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
            Section("title-release".localized) {
                release
                appVersion
                buildNumber
                source
                license
            }
            Section("title-dependencies".localized) {
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
        .navigationTitle("title-about".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $externalLinkURL) { SafariView(url: $0) }
        .task { await getDependencies() }
        #endif
    }
    
    private var about: some View {
        Text("about-description".localized)
    }
    
    private var release: some View {
        Text("about-license-description".localized)
    }
    
    private var appVersion: some View {
        Attribute(title: "title-version".localized,
                  detail: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
    }
    
    private var buildNumber: some View {
        Attribute(title: "title-build".localized, detail: Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
    }
    
    private var ourWebsite: some View {
        Button("title-our-website".localized) {
            externalLinkURL = URL(string: "https://www.kiwix.org")
        }
    }
    
    private var source: some View {
        Button("title-source".localized) {
            externalLinkURL = URL(string: "https://github.com/kiwix/apple")
        }
    }
    
    private var license: some View {
        Button("about-license".localized) {
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
