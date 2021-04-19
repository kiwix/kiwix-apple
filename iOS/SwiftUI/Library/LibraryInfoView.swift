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
    @AppStorage("backupDocumentDirectory") private var backupDocumentDirectory: Bool = false
    
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
                Toggle(isOn: $autoRefresh, label: { Text("Auto update") })
            }
            Section(header: Text("Backup"), footer: Text("Does not apply to files that were opened in place.")) {
                Toggle(
                    isOn: $backupDocumentDirectory,
                    label: { Text("Include files in backup") }
                ).onChange(of: backupDocumentDirectory, perform: { value in
                    
                })
            }
        }.listStyle(InsetGroupedListStyle())
    }
}
