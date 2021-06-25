//
//  LibraryInfoView.swift
//  Kiwix
//
//  Created by Chris Li on 4/11/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import Defaults

@available(iOS 13.0, *)
struct LibraryInfoView: View {
    @Default(.libraryAutoRefresh) var libraryAutoRefresh
    @Default(.backupDocumentDirectory) var backupDocumentDirectory
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        List {
            Section(header: Text("Catalog")) {
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
                    if let lastRefreshTime = Defaults[.libraryLastRefresh] {
                        if Date().timeIntervalSince(lastRefreshTime) < 120 {
                            Text("Just Now").foregroundColor(.secondary)
                        } else {
                            Text(RelativeDateTimeFormatter().localizedString(for: lastRefreshTime, relativeTo: Date()))
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
        }.insetGroupedListStyle()
    }
    
    private class ViewModel: ObservableObject {
        @Published var isRefreshing = false
        
        private var operationObserver: NSKeyValueObservation?
        private var backupDocumentDirectoryCancellable: AnyCancellable?
        private var libraryAutoRefreshCancellable: AnyCancellable?
        
        init() {
            if let operation = LibraryOperationQueue.shared.currentOPDSRefreshOperation {
                isRefreshing = !operation.isFinished
                configureObserver(operation)
            }
            backupDocumentDirectoryCancellable = Defaults.publisher(.backupDocumentDirectory)
                .sink { enabled in LibraryService.shared.applyBackupSetting(isBackupEnabled: enabled.newValue) }
            libraryAutoRefreshCancellable = Defaults.publisher(.libraryAutoRefresh)
                .sink { _ in LibraryService.shared.applyAutoUpdateSetting() }
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
            configureObserver(operation)
        }
        
        private func configureObserver(_ operation: OPDSRefreshOperation) {
            operationObserver = operation.observe(
                \.isFinished, options: .new
            ) { [weak self] (operation, _) in
                DispatchQueue.main.sync {
                    self?.isRefreshing = !operation.isFinished
                }
            }
        }
    }
}
