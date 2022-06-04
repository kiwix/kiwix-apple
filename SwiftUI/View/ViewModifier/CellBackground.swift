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
            return Color.black.opacity(0.2)
        case (.dark, false):
            return Color.gray.opacity(0.2)
        case (.light, true):
            return Color.gray.opacity(0.2)
        case (.light, false), (_, _):
            #if os(macOS)
            return Color.white
            #elseif os(iOS)
            return Color.gray.opacity(0.1)
            #endif
        }
    }
}
