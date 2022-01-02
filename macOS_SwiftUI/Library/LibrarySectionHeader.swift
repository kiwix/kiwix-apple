//
//  LibrarySectionHeader.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct LibrarySectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: .infinity, style: .continuous)
                    .stroke(.tertiary, lineWidth: 1)
            )
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: .infinity, style: .continuous)
            )
    }
}

struct LibrarySectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        LibrarySectionHeader(title: "Best of Wikipedia").padding()
    }
}
