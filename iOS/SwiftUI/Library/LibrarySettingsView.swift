//
//  LibrarySettingsView.swift
//  Kiwix
//
//  Created by Chris Li on 4/11/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import Defaults

@available(iOS 13.0, *)
struct LibrarySettingsView: View {
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @Default(.libraryLastRefresh) private var libraryLastRefresh
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        List {
            if libraryLastRefresh != nil {
                Section {
                    NavigationLink("Languages", destination: LibraryLanguageView())
                }
            }
            Section(header: Text("Updates")) {
                ActionCell(title: viewModel.isRefreshing ? "Refreshing..." : "Update Now") {
                    viewModel.refresh()
                }.disabled(viewModel.isRefreshing)
            }
            Section(footer: Text(
                """
                When enabled, the library catalog will be updated both when library is opened \
                and utilizing iOS's Background App Refresh feature.
                """
            )) {
                HStack {
                    Text("Last update")
                    Spacer()
                    if let lastRefresh = libraryLastRefresh {
                        if Date().timeIntervalSince(lastRefresh) < 120 {
                            Text("Just Now").foregroundColor(.secondary)
                        } else {
                            Text(RelativeDateTimeFormatter().localizedString(for: lastRefresh, relativeTo: Date()))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Never").foregroundColor(.secondary)
                    }
                }
                Toggle(isOn: $libraryAutoRefresh, label: { Text("Auto update") })
            }
            Section(header: Text("Backup"), footer: Text("Does not apply to files that were opened in place.")) {
                Toggle(isOn: $backupDocumentDirectory, label: { Text("Include files in backup") })
            }
        }
        .insetGroupedListStyle()
    }
    
    private class ViewModel: ObservableObject {
        @Published var isRefreshing = false
        
        private var refreshObserver: NSKeyValueObservation?
        private let autoRefreshObserver = Defaults.observe(.libraryAutoRefresh) { _ in
            LibraryService.shared.applyAutoUpdateSetting()
        }
        private let backupDocumentDirectoryObserver = Defaults.observe(.backupDocumentDirectory) { change in
            LibraryService.shared.applyBackupSetting(isBackupEnabled: change.newValue)
        }
        
        init() {
            if let operation = LibraryOperationQueue.shared.currentOPDSRefreshOperation {
                isRefreshing = !operation.isFinished
                configureRefreshObserver(operation)
            }
        }
        
        func refresh() {
            let operation: OPDSRefreshOperation = {
                if let operation = LibraryOperationQueue.shared.currentOPDSRefreshOperation {
                    return operation
                } else {
                    let operation = OPDSRefreshOperation()
                    LibraryOperationQueue.shared.addOperation(operation)
                    return operation
                }
            }()
            isRefreshing = true
            configureRefreshObserver(operation)
        }
        
        private func configureRefreshObserver(_ operation: OPDSRefreshOperation) {
            refreshObserver = operation.observe(
                \.isFinished, options: .new
            ) { [weak self] (operation, _) in
                DispatchQueue.main.sync {
                    self?.isRefreshing = !operation.isFinished
                }
            }
        }
    }
}
