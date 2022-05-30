//
//  SearchFilter.swift
//  Kiwix
//
//  Created by Chris Li on 5/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SearchFilter: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: NSPredicate(format: "fileURLBookmark != nil"),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        if zimFiles.isEmpty {
            Message(text: "No opened zim files")
        } else {
            #if os(macOS)
            VStack(spacing: 0) {
                Divider()
                filterHeader
                    .padding(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 10))
                    .background(.ultraThinMaterial)
                Divider()
                List(zimFiles) { zimFile in
                    Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                        zimFile.includedInSearch
                    }, set: {
                        zimFile.includedInSearch = $0
                        try? managedObjectContext.save()
                    }))
                }
            }
            #elseif os(iOS)
            List {
                Section {
                    ForEach(zimFiles) { zimFile in
                        Button {
                            zimFile.includedInSearch.toggle()
                            try? managedObjectContext.save()
                        } label: {
                            HStack {
                                ZimFileRow(zimFile).foregroundColor(.primary)
                                Spacer()
                                if zimFile.includedInSearch {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                }
                            }
                        }
                    }
                } header: { filterHeader }
            }
            #endif
        }
    }
    
    var filterHeader: some View {
        HStack {
            Text("Include in Search").fontWeight(.medium)
            Spacer()
            if allIncluded {
                Button { selectNoZimFiles() } label: {
                    Text("None").font(.caption).fontWeight(.medium)
                }
            } else {
                Button { selectAllZimFiles() } label: {
                    Text("All").font(.caption).fontWeight(.medium)
                }
            }
        }
    }
    
    var allIncluded: Bool {
        zimFiles.map { $0.includedInSearch }.reduce(true) { $0 && $1 }
    }
    
    private func selectAllZimFiles() {
        managedObjectContext.perform {
            zimFiles.forEach { $0.includedInSearch = true }
            try? managedObjectContext.save()
        }
    }
    
    private func selectNoZimFiles() {
        managedObjectContext.perform {
            zimFiles.forEach { $0.includedInSearch = false }
            try? managedObjectContext.save()
        }
    }
}
