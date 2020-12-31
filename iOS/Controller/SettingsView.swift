//
//  SettingsView.swift
//  iOS
//
//  Created by Chris Li on 12/30/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink("About", destination: Text("About"))
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
            }.listStyle(GroupedListStyle())
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

@available(iOS 13.0.0, *)
struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("""
                     Kiwix enables you to have the whole Wikipedia at hand wherever you go! On a boat, in the middle \
                     of nowhere or in jail, Kiwix gives you access to the whole human knowledge. You don't need \
                     Internet, everything is stored on your iOS device!
                     """
                ).multilineTextAlignment(.leading)
            }
            Section(header: Text("Release")) {
                Text("This software is released under the terms of the GNU General Public License version 3.")
                Button("Source") {
                    
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
    }
    
    struct Dependency: View {
        let name: String
        let license: String
        
        var body: some View {
            NavigationLink(
                destination: Text("Destination"),
                label: {
                    HStack {
                        Text(name)
                        Spacer()
                        Text(license).foregroundColor(.secondary)
                    }
                }
            )
        }
    }
        
}


@available(iOS 13.0.0, *)
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView().previewDevice("iPhone 12 Pro")
    }
}
