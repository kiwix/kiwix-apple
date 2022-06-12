//
//  LibrarySettings.swift
//  Kiwix
//
//  Created by Chris Li on 6/11/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct LibrarySettings: View {
    @AppStorage("backupDocumentDirectory") var backupDocumentDirectory = false
    @AppStorage("libraryAutoRefresh") var libraryAutoRefresh = false
    @State var selectedLanguages = Set<String>()
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            HStack(alignment :.top) {
                Text("Updates:").frame(width: 80, alignment: .trailing)
                VStack(alignment: .leading, spacing: 16) {
                    Button("Update Now") {
                        
                    }
                    VStack(alignment: .leading) {
                        Toggle("Auto update", isOn: $libraryAutoRefresh)
                        Text("When enabled, the library catalog will be updated automatically when outdated.")
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            Divider()
            HStack(alignment :.top) {
                Text("Languages:").frame(width: 80, alignment: .trailing)
                List(selection: $selectedLanguages) {
                    Text("lang 1")
                    Text("lang 2")
                    Text("lang 3")
                    Text("this could be a table")
                }.cornerRadius(6)
            }
        }
        .padding()
        .tabItem { Label("Library", systemImage: "folder.badge.gearshape") }
        #elseif os(iOS)
        List {
            Section {
                HStack {
                    Text("Last update")
                    Spacer()
                    Text("Never").foregroundColor(.secondary)
                }
                Button("Update Now") {
                    
                }
                Toggle("Auto update", isOn: $libraryAutoRefresh)
            } header: {
                Text("Updates")
            } footer: {
                Text("When enabled, the library catalog will be updated automatically when outdated.")
            }
            Section {
                Toggle("Include zim files in backup", isOn: $backupDocumentDirectory)
            } header: {
                Text("Backup")
            } footer: {
                Text("Does not apply to files opened in place.")
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct LibrarySettings_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        TabView { LibrarySettings() }.frame(width: 480).preferredColorScheme(.light)
        TabView { LibrarySettings() }.frame(width: 480).preferredColorScheme(.dark)
        #elseif os(iOS)
        NavigationView { LibrarySettings() }
        #endif
    }
}
