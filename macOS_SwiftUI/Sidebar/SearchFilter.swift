//
//  SearchFilterView.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/16/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

/// Controls which zim files are included in search.
struct SearchFilterView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(sortDescriptors: []) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("Include in Search").fontWeight(.medium)
                Spacer()
                if zimFiles.map {$0.includedInSearch }.reduce(true) { $0 && $1 } {
                    Button { selectNone() } label: {
                        Text("None").font(.caption).fontWeight(.medium)
                    }
                } else {
                    Button { selectAll() } label: {
                        Text("All").font(.caption).fontWeight(.medium)
                    }
                }
            }.padding(.vertical, 5).padding(.leading, 16).padding(.trailing, 10).background(.regularMaterial)
            Divider()
            List {
                ForEach(zimFiles, id: \.fileID) { zimFile in
                    Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                        zimFile.includedInSearch
                    }, set: {
                        zimFile.includedInSearch = $0
                        try? managedObjectContext.save()
                    }))
                }
            }
        }.frame(height: 180)
    }
    
    private func selectAll() {
        let request = ZimFile.fetchRequest()
        try? managedObjectContext.fetch(request).forEach { zimFile in
            zimFile.includedInSearch = true
        }
        try? managedObjectContext.save()
    }
    
    private func selectNone() {
        let request = ZimFile.fetchRequest()
        try? managedObjectContext.fetch(request).forEach { zimFile in
            zimFile.includedInSearch = false
        }
        try? managedObjectContext.save()
    }
}
