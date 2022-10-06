//
//  SheetView.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 7/6/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
struct SheetView<Content: View>: View {
    @Environment(\.presentationMode) private var presentationMode
    
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            content.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }.navigationViewStyle(.stack)
    }
}
#endif
