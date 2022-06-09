//
//  CellBackground.swift
//  Kiwix
//
//  Created by Chris Li on 6/4/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct CellBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    let isHovering: Bool
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var backgroundColor: Color {
        switch (colorScheme, isHovering) {
        case (.dark, true):
            return Color(white: 0.25)
        case (.dark, false):
            #if os(macOS)
            return Color(white: 0.125)
            #elseif os(iOS)
            return Color(white: 0.175)
            #endif
        case (.light, true):
            return Color(white: 0.9)
        case (.light, false), (_, _):
            #if os(macOS)
            return Color.white
            #elseif os(iOS)
            return Color(white: 0.96)
            #endif
        }
    }
}
