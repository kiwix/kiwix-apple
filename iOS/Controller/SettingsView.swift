//
//  SettingsView.swift
//  iOS
//
//  Created by Chris Li on 12/30/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SafariServices
import SwiftUI

import Defaults

@available(iOS 13.0, *)
struct SettingsView: View {
    @Default(.sideBarDisplayMode) var sideBarDisplayMode
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Picker("Side Bar", selection: $sideBarDisplayMode) {
                            ForEach(SideBarDisplayMode.allCases) { Text($0.description).tag($0) }
                        }
                    }
                }
                Section {
                    Button("Send Feedback") {
                        
                    }
                    Button("Rate the App") {
                        
                    }
                }
                Section {
                    NavigationLink("About", destination: AboutView())
                }
            }
            .navigationBarTitle("Settings")
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

@available(iOS 13.0, *)
fileprivate struct AboutView: View {
    @State var externalLinkURL: URL?
    
    var body: some View {
        List {
            Section {
                Text("""
                     Kiwix is an offline reader for online content like Wikipedia, Project Gutenberg, or TED Talks. \
                     It makes knowledge available to people with no or limited internet access. \
                     The software as well as the content is free to use for anyone.
                     """
                ).multilineTextAlignment(.leading)
                Button("Our Website") {
                    externalLinkURL = URL(string: "https://www.kiwix.org")
                }
            }
            Section(header: Text("Release")) {
                Text("This app is released under the terms of the GNU General Public License version 3.")
                Button("Source") {
                    externalLinkURL = URL(string: "https://github.com/kiwix/apple")
                }
                Button("GNU General Public License v3") {
                    externalLinkURL = URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")
                }
            }
            Section(header: Text("Dependencies")) {
                Dependency(name: "kiwix-lib", license: "GPLv3")
                Dependency(name: "libzim", license: "GPLv2")
                Dependency(name: "Xapian", license: "GPLv2")
                Dependency(name: "ICU", license: "ICU")
                Dependency(name: "Realm", license: "Apachev2")
                Dependency(name: "SwiftSoup", license: "MIT")
                Dependency(name: "Defaults", license: "MIT")
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("About")
        .sheet(item: $externalLinkURL) { SafariView(url: $0) }
    }
    
    struct Dependency: View {
        let name: String
        let license: String
        
        var body: some View {
            HStack {
                Text(name)
                Spacer()
                Text(license).foregroundColor(.secondary)
            }
        }
    }
    
    struct SafariView: UIViewControllerRepresentable {
        let url: URL

        func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
            SFSafariViewController(url: url)
        }
        
        func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
    }
}

@available(iOS 13.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView().previewDevice("iPhone 12 Pro")
    }
}
