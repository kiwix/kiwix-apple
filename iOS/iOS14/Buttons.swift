//
//  Buttons.swift
//  Kiwix
//
//  Created by Chris Li on 10/24/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct SwiftUIBarButton: View {
    let iconName: String
    @State var isPushed: Bool = false
    var action: (() -> Void)?
    
    var image: some View {
        Image(systemName: iconName)
            .font(Font.body.weight(.regular))
            .imageScale(.large)
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            ZStack(alignment: .center) {
                if isPushed {
                    Color(.systemBlue).cornerRadius(6)
                    image.foregroundColor(Color(.systemBackground))
                } else {
                    image
                }
            }.frame(width: 32, height: 32)
        }
    }
}
