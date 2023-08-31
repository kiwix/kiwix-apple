//
//  GridCommon.swift
//  Kiwix
//
//  Created by Chris Li on 5/22/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

/// Add padding around the modified view. On iOS, the padding is adjusted so that the modified view align with the search bar.
struct GridCommon: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let edges: Edge.Set?
    
    init(edges: Edge.Set? = nil) {
        self.edges = edges
    }
    
    func body(content: Content) -> some View {
        #if os(macOS)
        ScrollView {
            content.padding(edges ?? .all)
        }
        #elseif os(iOS)
        GeometryReader { proxy in
            ScrollView {
                content.padding(
                    edges ?? (
                        horizontalSizeClass == .compact || verticalSizeClass == .compact ? [.horizontal, .bottom] : .all
                    ),
                    proxy.size.width > 375 && verticalSizeClass == .regular ? 20 : 16
                )
            }
        }
        #endif
    }
}

