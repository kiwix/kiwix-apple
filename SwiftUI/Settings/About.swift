//
//  About.swift
//  Kiwix
//
//  Created by Chris Li on 6/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct About: View {
    @State var externalLinkURL: URL?
    
    var body: some View {
        List {
            Section {
                Text(
                     """
                     Kiwix is an offline reader for online content like Wikipedia, Project Gutenberg, or TED Talks. \
                     It makes knowledge available to people with no or limited internet access. \
                     The software as well as the content is free to use for anyone.
                     """
                )
                .lineLimit(nil)
                .minimumScaleFactor(0.5) // to avoid unnecessary truncation (three dots)
                Button("Our Website") { externalLinkURL = URL(string: "https://www.kiwix.org") }
            } header: { Text("About") }
            Section {
                Text("This app is released under the terms of the GNU General Public License version 3.")
                Button("Source") { externalLinkURL = URL(string: "https://github.com/kiwix/apple") }
                Button("GNU General Public License v3") {
                    externalLinkURL = URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")
                }
            } header: { Text("Release") }
            Section {
                Dependency(name: "libkiwix", license: "GPLv3", version: "9.4.1")
                Dependency(name: "libzim", license: "GPLv2", version: "6.3.2")
                Dependency(name: "Xapian", license: "GPLv2")
                Dependency(name: "ICU", license: "ICU")
                Dependency(name: "Fuzi", license: "MIT")
            } header: { Text("Dependencies") }
        }
        .modifier(ExternalLinkHandler(url: $externalLinkURL))
        .modifier(PlatformDifferenceHandler())
    }
    
    struct Dependency: View {
        let name: String
        let license: String
        let version: String?
        
        init(name: String, license: String, version: String? = nil) {
            self.name = name
            self.license = license
            self.version = version
        }
        
        var body: some View {
            HStack {
                Text(name)
                Spacer()
                Text(license).foregroundColor(.secondary)
                if let version = version {
                    Text("(\(version))").foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct ExternalLinkHandler: ViewModifier {
    @Binding var url: URL?
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onChange(of: url) { url in
            guard let url = url else { return }
            NSWorkspace.shared.open(url)
        }
        #elseif os(iOS)
        content.sheet(item: $url) { SafariView(url: $0).ignoresSafeArea(.container, edges: .all) }
        #endif
    }
}

private struct PlatformDifferenceHandler: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .listStyle(.sidebar)
            .cornerRadius(6)
            .shadow(radius: 1)
            .padding()
            .tabItem { Label("About", systemImage: "info.circle") }
        #elseif os(iOS)
        content.navigationTitle("About")
        #endif
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
