//
//  SheetContent.swift
//  Kiwix
//
//  Created by Chris Li on 7/6/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SheetContent<Content: View>: View {
    @Environment(\.presentationMode) private var presentationMode
    
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        NavigationView {
            content.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }.navigationViewStyle(.stack)
        #endif
    }
}
