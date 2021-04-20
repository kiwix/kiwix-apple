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
    
    var body: some View {
        List {
            Section(header: Text("Catalog")) {
                ActionCell(title: "Update Now") {
                    
                }
            }
            Section {
                HStack {
                    Text("Last update")
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
}
