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
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        if let outlineItems = sceneViewModel.currentArticleOutlineItems {
            List(outlineItems, id: \.index) { outlineItem in
                Button {
                    sceneViewModel.navigateToOutlineItem(index: outlineItem.index)
                } label: {
                    if outlineItem.level == 1 {
                        HStack {
                            Spacer()
                            Text(outlineItem.text).bold()
                            Spacer()
                        }
                    } else {
                        Text(outlineItem.text).padding(.leading, 20 * CGFloat(outlineItem.level - 2))
                    }
                }
            }
        } else {
            Text("No Outline")
        }
    }
}
