//
//  OutlineView.swift
//  Kiwix
//
//  Created by Chris Li on 11/10/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct OutlineView: View {
    private let outlineItems: [OutlineItem]?
    @Binding private var isPresented: Bool
    
    init(outlineItems: [OutlineItem]?, isPresented: Binding<Bool>) {
        self.outlineItems = outlineItems
        self._isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            if let outlineItems = outlineItems {
                List(outlineItems, id: \.index) { outlineItem in
                    Text(outlineItem.text)
                }
                .navigationBarTitle("Outline", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            } else {
                Text("No Outline")
            }
        }
    }
}
