//
//  LibrarySettings.swift
//  Kiwix
//
//  Created by Chris Li on 10/2/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct LibrarySettings: View {
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @Default(.libraryLanguageCodes) private var libraryLanguageCodes
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            SettingSection(name: "Catalog") {
                HStack(spacing: 6) {
                    Button("Refresh Now") {
                        viewModel.startRefresh(isUserInitiated: true)
                    }.disabled(viewModel.isRefreshing)
                    if viewModel.isRefreshing {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                    }
                    Spacer()
                    Text("Last refresh:").foregroundColor(.secondary)
                    LibraryLastRefreshTime().foregroundColor(.secondary)
                }
                VStack(alignment: .leading) {
                    Toggle("Auto refresh", isOn: $libraryAutoRefresh)
                    Text("When enabled, the library catalog will be refreshed automatically when outdated.")
                        .foregroundColor(.secondary)
                }
            }
            SettingSection(name: "Languages", alignment: .top) {
                LanguageSelector()
            }
        }
        .padding()
        .tabItem { Label("Library", systemImage: "folder.badge.gearshape") }
        #elseif os(iOS)
        Section {
            NavigationLink {
                LanguageSelector()
            } label: {
                HStack {
                    Text("Languages")
                    Spacer()
                    if libraryLanguageCodes.count == 1,
                       let languageCode = libraryLanguageCodes.first,
                        let languageName = Locale.current.localizedString(forLanguageCode: languageCode) {
                        Text(languageName).foregroundColor(.secondary)
                    } else if libraryLanguageCodes.count > 1 {
                        Text("\(libraryLanguageCodes.count)").foregroundColor(.secondary)
                    }
                }
            }
            Toggle("Download using cellular", isOn: $downloadUsingCellular)
        } header: {
            Text("Library")
        } footer: {
            Text("Change will only apply to new download tasks.")
        }
        Section {
            HStack {
                Text("Last refresh")
                Spacer()
                LibraryLastRefreshTime().foregroundColor(.secondary)
            }
            if viewModel.isRefreshing {
                HStack {
                    Text("Refreshing...").foregroundColor(.secondary)
                    Spacer()
                    ProgressView().progressViewStyle(.circular)
                }
            } else {
                Button("Refresh Now") {
                    Task { viewModel.startRefresh(isUserInitiated: true) }
                }
            }
            Toggle("Auto refresh", isOn: $libraryAutoRefresh)
        } header: {
            Text("Catalog")
        } footer: {
            Text("When enabled, the library catalog will be refreshed automatically when outdated.")
        }
        Section {
            Toggle("Include zim files in backup", isOn: $backupDocumentDirectory)
        } header: {
            Text("Backup")
        } footer: {
            Text("Does not apply to files opened in place.")
        }
        #endif
    }
}

struct LibrarySettings_Previews: PreviewProvider {
    static var previews: some View {
        TabView { LibrarySettings() }.frame(width: 480).preferredColorScheme(.light)
        TabView { LibrarySettings() }.frame(width: 480).preferredColorScheme(.dark)
    }
}
