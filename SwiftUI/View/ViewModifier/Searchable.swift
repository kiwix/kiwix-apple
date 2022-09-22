//
//  Searchable.swift
//  Kiwix
//
//  Created by Chris Li on 6/8/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Searchable: ViewModifier {
    @Binding var searchText: String
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            content.searchable(text: $searchText)
        } else {
            content
        }
    }
}
