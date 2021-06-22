//
//  LibraryInfoView.swift
//  Kiwix
//
//  Created by Chris Li on 4/11/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct LibraryInfoView: View {
    @AppStorage("libraryAutoRefresh") private var autoRefresh: Bool = true
    @AppStorage("backupDocumentDirectory") private var backupEnabled: Bool = false
    
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
                    if let lastRefreshTime = UserDefaults.standard.value(forKey: "libraryLastRefreshTime") as? Date {
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
                Toggle(
                    isOn: $autoRefresh, label: { Text("Auto update") }
                ).onChange(of: autoRefresh, perform: { value in
                    LibraryService.shared.applyAutoUpdateSetting()
                })
            }
            Section(header: Text("Backup"), footer: Text("Does not apply to files that were opened in place.")) {
                Toggle(
                    isOn: $backupEnabled,
                    label: { Text("Include files in backup") }
                ).onChange(of: backupEnabled, perform: { enabled in
                    LibraryService.shared.applyBackupSetting(isBackupEnabled: enabled)
                })
            }
        }.listStyle(InsetGroupedListStyle())
    }
    
    private class ViewModel: ObservableObject {
        @Published var isRefreshing = false
        
        private var operationObserver: NSKeyValueObservation?
        
        init() {
            guard let operation = LibraryOperationQueue.shared.currentOPDSRefreshOperation else { return }
            isRefreshing = !operation.isFinished
            configureObserver(operation)
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
