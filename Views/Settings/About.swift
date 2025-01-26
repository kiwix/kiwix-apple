// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI

import CoreKiwix

struct About: View {
    @State private var dependencies = [Dependency]()
    @State private var externalLinkURL: URL?

    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            SettingSection(name: LocalString.settings_about_title) {
                about
                ourWebsite
            }
            SettingSection(name: LocalString.settings_about_release) {
                release
                HStack {
                    source
                    license
                }
            }
            SettingSection(name: LocalString.settings_about_dependencies, alignment: .top) {
                Table(dependencies) {
                    TableColumn(LocalString.settings_about_dependencies_name, value: \.name)
                    TableColumn(LocalString.settings_about_dependencies_license) { dependency in
                        Text(dependency.license ?? "")
                    }
                    TableColumn(LocalString.settings_about_dependencies_version, value: \.version)
                }.tableStyle(.bordered(alternatesRowBackgrounds: true))
            }
        }
        .padding()
        .tabItem { Label(LocalString.settings_about_title, systemImage: "info.circle") }
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
            Section(LocalString.settings_about_release) {
                release
                appVersion
                buildNumber
                source
                license
            }
            Section(LocalString.settings_about_dependencies) {
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
        .navigationTitle(LocalString.settings_about_title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: externalLinkURL) { url in
            guard let url = url else { return }
            UIApplication.shared.open(url)
        }
        .task { await getDependencies() }
        #endif
    }

    private var about: some View {
        Text(Brand.aboutText)
    }

    private var release: some View {
        Text(LocalString.settings_about_license_description)
    }

    private var appVersion: some View {
        Attribute(title: LocalString.settings_about_appverion_title,
                  detail: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
    }

    private var buildNumber: some View {
        Attribute(title: LocalString.settings_about_build_title,
                  detail: Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
    }

    private var ourWebsite: some View {
        Button(LocalString.settings_about_our_website_button) {
            externalLinkURL = URL(string: "\(Brand.aboutWebsite)")
        }
    }

    private var source: some View {
        Button(LocalString.settings_about_source_title) {
            externalLinkURL = URL(string: "https://github.com/kiwix/kiwix-apple")
        }
    }

    private var license: some View {
        Button(LocalString.settings_about_button_license) {
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
    NavigationStack { About() }
    #endif
}
