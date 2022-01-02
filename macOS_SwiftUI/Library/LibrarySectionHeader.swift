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
    let category: Category
    let imageData: Data?
    let imageURL: URL?
    
    var body: some View {
        Label {
            Text(title).fontWeight(.medium)
        } icon: {
            Favicon(category: category, imageData: imageData, imageURL: imageURL)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.tertiary, lineWidth: 1)
        )
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
        )
    }
}

struct LibrarySectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        LibrarySectionHeader(
            title: "Best of Wikipedia",
            category: .wikipedia,
            imageData: nil,
            imageURL: nil
        ).preferredColorScheme(.light).padding()
        LibrarySectionHeader(
            title: "Best of Wikipedia",
            category: .wikipedia,
            imageData: nil,
            imageURL: nil
        ).preferredColorScheme(.dark).padding()
    }
}
