//
//  SearchView.swift
//  Kiwix
//
//  Created by Chris Li on 10/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct SearchView: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .trailing) {
                List{
                    
                }.listStyle(SidebarListStyle())
                Divider()
            }
            .frame(minWidth: 300, idealWidth: 400, maxWidth: 400)
            List{}
        }
    }
}
