//
//  LibrarySettings.swift
//  Kiwix
//
//  Created by Chris Li on 6/11/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif
import SwiftUI

import Defaults

struct LibrarySettings: View {
    @Default(.backupDocumentDirectory) var backupDocumentDirectory
    @Default(.libraryAutoRefresh) var autoRefresh
    @Default(.libraryLastRefresh) var lastRefresh
    @StateObject var viewModel = LibraryViewModel()
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            HStack(alignment :.top) {
                Text("Catalog:").frame(width: 80, alignment: .trailing)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 6) {
                        Button("Refresh Now") {
                            Task { try? await viewModel.refresh(isUserInitiated: true) }
                        }.disabled(viewModel.isRefreshing)
                        if viewModel.isRefreshing {
                            ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                        }
                        Spacer()
                        Text("Last refresh:").foregroundColor(.secondary)
                        lastRefreshTime.foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading) {
                        Toggle("Auto refresh", isOn: $autoRefresh)
                        Text("When enabled, the library catalog will be refreshed automatically when outdated.")
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            Divider()
            HStack(alignment :.top) {
                Text("Languages:").frame(width: 80, alignment: .trailing)
                LanguageSelector().environmentObject(viewModel)
            }
        }
        .padding()
        .tabItem { Label("Library", systemImage: "folder.badge.gearshape") }
        #elseif os(iOS)
        List {
            if lastRefresh != nil {
                Section {
                    NavigationLink("Languages") {
                        LanguageSelector().navigationTitle("Languages").environmentObject(viewModel)
                    }
                }
            }
            Section {
                HStack {
                    Text("Last refresh")
                    Spacer()
                    lastRefreshTime.foregroundColor(.secondary)
                }
                if viewModel.isRefreshing {
                    HStack {
                        Text("Refreshing...").foregroundColor(.secondary)
                        Spacer()
                        ProgressView().progressViewStyle(.circular)
                    }
                } else {
                    Button("Refresh Now") {
                        Task { try? await viewModel.refresh(isUserInitiated: true) }
                    }
                }
                Toggle("Auto refresh", isOn: $autoRefresh)
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
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: autoRefresh) { isEnable in
            if isEnable {
                let request = BGAppRefreshTaskRequest(identifier: LibraryViewModel.backgroundTaskIdentifier)
                try? BGTaskScheduler.shared.submit(request)
            } else {
                BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: LibraryViewModel.backgroundTaskIdentifier)
            }
        }
        .onChange(of: backupDocumentDirectory) { _ in Kiwix.applyZimFileBackupSetting() }
        #endif
    }
    
    @ViewBuilder
    var lastRefreshTime: some View {
        if let lastRefresh = lastRefresh {
            if Date().timeIntervalSince(lastRefresh) < 120 {
                Text("Just Now")
            } else {
                Text(RelativeDateTimeFormatter().localizedString(for: lastRefresh, relativeTo: Date()))
            }
        } else {
            Text("Never")
        }
    }
}

#if os(macOS)
private struct LanguageSelector: View {
    @Default(.libraryLanguageCodes) var selected
    @EnvironmentObject var viewModel: LibraryViewModel
    @State private var languages = [Language]()
    @State private var sortOrder = [KeyPathComparator(\Language.count, order: .reverse)]
    
    var body: some View {
        Table(languages, sortOrder: $sortOrder) {
            TableColumn("") { language in
                Toggle("", isOn: Binding {
                    selected.contains(language.code)
                } set: { isSelected in
                    if isSelected {
                        selected.insert(language.code)
                    } else {
                        selected.remove(language.code)
                    }
                })
            }.width(14)
            TableColumn("Name", value: \.name)
            TableColumn("Count", value: \.count) { language in Text(language.count.formatted()) }
        }
        .tableStyle(.bordered(alternatesRowBackgrounds: true))
        .onChange(of: sortOrder) { languages.sort(using: $0) }
        .task {
            languages = await viewModel.fetchLanguages()
            languages.sort(using: sortOrder)
        }
    }
}
#elseif os(iOS)
private struct LanguageSelector: View {
    @EnvironmentObject var viewModel: LibraryViewModel
    @State private var showing = [Language]()
    @State private var hiding = [Language]()
    
    var body: some View {
        List() {
            Section {
                if showing.isEmpty {
                    Text("No language").foregroundColor(.secondary)
                } else {
                    ForEach(showing) { language in
                        Button { hide(language) } label: { LanguageLabel(language: language) }
                    }
                }
            } header: { Text("Showing") }
            Section {
                ForEach(hiding) { language in
                    Button { show(language) } label: { LanguageLabel(language: language) }
                }
            } header: { Text("Hiding") }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            Task {
                var languages = await viewModel.fetchLanguages()
                languages.sort { lhs, rhs in
                    lhs.count > rhs.count
                }
                hiding = languages
            }
        }
    }
    
    private func show(_ language: Language) {
        withAnimation {
            hiding.removeAll { $0.code == language.code }
            showing.append(language)
            showing.sort(by: compare(lhs:rhs:))
        }
    }
    
    private func hide(_ language: Language) {
        withAnimation {
            showing.removeAll { $0.code == language.code }
            hiding.append(language)
            hiding.sort(by: compare(lhs:rhs:))
        }
    }
    
    private func compare(lhs: Language, rhs: Language) -> Bool {
        return lhs.count > rhs.count
    }
}

struct LanguageLabel: View {
    let language: Language
    
    var body: some View {
        HStack {
            Text(language.name).foregroundColor(.primary)
            Spacer()
            Text("\(language.count)").foregroundColor(.secondary)
        }
    }
}
#endif

struct LibrarySettings_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        TabView { LibrarySettings() }.frame(width: 480).preferredColorScheme(.light)
        TabView { LibrarySettings() }.frame(width: 480).preferredColorScheme(.dark)
        #elseif os(iOS)
        NavigationView { LibrarySettings() }
        NavigationView { LanguageSelector() }
        #endif
    }
}
