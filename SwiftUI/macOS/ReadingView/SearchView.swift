//
//  SearchView.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.withFileURLBookmarkPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isShowingMoreRecentSearch = false
    @State private var selectedRecentSearchText: String?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                Color.clear
                content
                    .background(Material.regular)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
                    .frame(width: min(proxy.size.width * 0.75, 425), height: min(proxy.size.height * 0.8, 600))
                    .padding(8)
            }
        }
    }
    
    var content: some View {
        List(selection: $selectedRecentSearchText) {
            recentSearch
            filter
        }.background(Color.green)
    }
    
    var recentSearch: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(1..<13) { index in
                    Button("recent search item \(index)") {
                        
                    }
                }
            }
        } header: { Text("Recent Search") }
    }
    
    var filter: some View {
        Section {
            ForEach(zimFiles) { zimFile in
                Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                    zimFile.includedInSearch
                }, set: {
                    zimFile.includedInSearch = $0
                    try? managedObjectContext.save()
                }))
            }
        } header: { Text("Included in Search") }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
