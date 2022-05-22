//
//  LibraryGridPadding.swift
//  Kiwix
//
//  Created by Chris Li on 5/22/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

/// Add padding around the modified view. On iOS, the padding is adjusted so that the modified view align with the search bar.
struct LibraryGridPadding: ViewModifier {
    let width: CGFloat
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.padding(.all)
        #elseif os(iOS)
        content.padding([.horizontal, .bottom], width > 375 ? 20 : 16)
        #endif
    }
}
