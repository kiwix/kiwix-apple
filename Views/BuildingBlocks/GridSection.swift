//
//  GridSection.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct GridSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        Section {
            content
        } header: {
            Text(title).font(.title3).fontWeight(.semibold)
        }
    }
}


struct GridSection_Previews: PreviewProvider {
    static var previews: some View {
        GridSection(title: "Header Text".localized) {
            Text("Content".localized)
        }
    }
}
