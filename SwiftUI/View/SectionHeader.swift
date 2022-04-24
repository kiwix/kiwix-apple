//
//  SectionHeader.swift
//  Kiwix
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
struct SectionHeader: View {
    let title: String
    let category: Category
    let imageData: Data?
    let imageURL: URL?
    
    var body: some View {
        Label {
            Text(title).fontWeight(.medium)
        } icon: {
            Favicon(category: category, imageData: imageData, imageURL: imageURL).frame(height: 18)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
        .background(
            .thickMaterial,
            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
        )
    }
}

@available(iOS 15.0, *)
struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeader(
            title: "Best of Wikipedia",
            category: .wikipedia,
            imageData: nil,
            imageURL: nil
        ).preferredColorScheme(.light).padding()
        SectionHeader(
            title: "Best of Wikipedia",
            category: .wikipedia,
            imageData: nil,
            imageURL: nil
        ).preferredColorScheme(.dark).padding()
    }
}
