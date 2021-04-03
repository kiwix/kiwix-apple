//
//  LibraryLanguageFilterView.swift
//  Kiwix
//
//  Created by Chris Li on 4/3/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct LibraryLanguageFilterView: View {
    @AppStorage("libraryLanguageSortingMode") var sortingMode: LibraryLanguageFilterSortingMode = .alphabetically
    var doneButtonTapped: () -> Void = {}
    
    
    var body: some View {
        List {
            
        }.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done", action: doneButtonTapped)
            }
            ToolbarItem(placement: ToolbarItemPlacement.principal) {
                Picker("Language Sorting Mode", selection: $sortingMode, content: {
                    Text("A-Z").tag(LibraryLanguageFilterSortingMode.alphabetically)
                    Text("By Count").tag(LibraryLanguageFilterSortingMode.byCount)
                })
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

@available(iOS 14.0, *)
struct LibraryLanguageFilterView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryLanguageFilterView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
            .previewDisplayName("iPhone 12 Pro")
    }
}
