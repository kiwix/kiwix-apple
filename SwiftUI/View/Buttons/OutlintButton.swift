//
//  OutlintButton.swift
//  Kiwix
//
//  Created by Chris Li on 5/27/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct OutlintButton: View {
    @Binding var sidebarDisplayMode: SidebarDisplayMode?
    
    var body: some View {
        Button {
            withAnimation(sidebarDisplayMode == nil ?  .easeOut(duration: 0.18) : .easeIn(duration: 0.18)) {
                sidebarDisplayMode = sidebarDisplayMode != .outline ? .outline : nil
            }
        } label: {
            Image(systemName: "list.bullet")
        }
    }
}
