//
//  SearchFilter.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 2/12/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

struct SearchFilter: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        List(zimFiles) { zimFile in
            Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                zimFile.includedInSearch
            }, set: {
                zimFile.includedInSearch = $0
                try? managedObjectContext.save()
            }))
        }.safeAreaInset(edge: .top) {
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
            .padding(.vertical, 5)
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .background(.ultraThinMaterial)
        }
    }
    
    var allIncluded: Bool {
        zimFiles.map { $0.includedInSearch }.reduce(true) { $0 && $1 }
    }
    
    private func selectAllZimFiles() {
        managedObjectContext.perform {
            zimFiles.forEach { $0.includedInSearch = true }
        }
        try? managedObjectContext.save()
    }
    
    private func selectNoZimFiles() {
        managedObjectContext.perform {
            zimFiles.forEach { $0.includedInSearch = false }
        }
        try? managedObjectContext.save()
    }
}

struct SearchFilter_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilter().frame(width: 250, height: 200)
    }
}
