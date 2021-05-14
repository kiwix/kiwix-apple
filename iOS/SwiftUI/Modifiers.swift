//
//  Modifiers.swift
//  Kiwix
//
//  Created by Chris Li on 10/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct ScrollableModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .padding(.horizontal, geometry.size.width > 400 ? 20 : 16)
                    .padding(.vertical, 16)
            }
        }
    }
}

@available(iOS 14.0, *)
struct ReadableWidthModifier: ViewModifier {
    private func calculateHorizontalPadding(size: CGSize) -> CGFloat {
        switch size.width {
        case 1000..<CGFloat.infinity:
            return max((size.width - 1000) / 2, 20)
        case 400..<1000:
            return 20
        default:
            return 10
        }
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                content.padding(.horizontal, calculateHorizontalPadding(size: geometry.size))
            }
        }
    }
}
