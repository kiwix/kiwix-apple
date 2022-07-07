//
//  SettingSection.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 6/21/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SettingSection<Content: View>: View {
    let name: String
    var content: () -> Content
    
    init(name: String, @ViewBuilder content: @escaping () -> Content) {
        self.name = name
        self.content = content
    }
    
    var body: some View {
        HStack(alignment :.top) {
            Text("\(name):").frame(width: 100, alignment: .trailing)
            VStack(alignment: .leading, spacing: 16, content: content)
            Spacer()
        }
    }
}
