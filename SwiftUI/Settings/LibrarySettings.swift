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
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.libraryAutoRefresh) private var autoRefresh
    @Default(.libraryLastRefresh) private var lastRefresh
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            SettingSection(name: "Catalog") {
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
            SettingSection(name: "Languages") {
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
    @Default(.libraryLanguageCodes) private var selected
    @EnvironmentObject private var viewModel: LibraryViewModel
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
    @Default(.libraryLanguageSortingMode) private var sortingMode
    @EnvironmentObject private var viewModel: LibraryViewModel
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
        .toolbar {
            Picker(selection: $sortingMode) {
                ForEach(LibraryLanguageSortingMode.allCases) { sortingMode in
                    Text(sortingMode.name).tag(sortingMode)
                }
            } label: {
                Label("Sorting", systemImage: "arrow.up.arrow.down")
            }.pickerStyle(.menu)
        }
        .onAppear {
            Task {
                var languages = await viewModel.fetchLanguages()
                languages.sort(by: LibraryViewModel.compareLanguage(lhs:rhs:))
                showing = languages.filter { Defaults[.libraryLanguageCodes].contains($0.code) }
                hiding = languages.filter { !Defaults[.libraryLanguageCodes].contains($0.code) }
            }
        }
        .onChange(of: sortingMode) { sortingMode in
            showing.sort(by: LibraryViewModel.compareLanguage(lhs:rhs:))
            hiding.sort(by: LibraryViewModel.compareLanguage(lhs:rhs:))
        }
    }
    
    private func show(_ language: Language) {
        Defaults[.libraryLanguageCodes].insert(language.code)
        withAnimation {
            hiding.removeAll { $0.code == language.code }
            showing.append(language)
            showing.sort(by: LibraryViewModel.compareLanguage(lhs:rhs:))
        }
    }
    
    private func hide(_ language: Language) {
        Defaults[.libraryLanguageCodes].remove(language.code)
        withAnimation {
            showing.removeAll { $0.code == language.code }
            hiding.append(language)
            hiding.sort(by: LibraryViewModel.compareLanguage(lhs:rhs:))
        }
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
