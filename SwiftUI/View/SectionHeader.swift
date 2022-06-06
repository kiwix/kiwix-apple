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
            Text(title).font(.title3).fontWeight(.semibold)
        } icon: {
            Favicon(category: category, imageData: imageData, imageURL: imageURL).frame(height: 20)
        }
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
        ).padding().previewLayout(.sizeThatFits).preferredColorScheme(.light)
        SectionHeader(
            title: "Best of Wikipedia",
            category: .wikipedia,
            imageData: nil,
            imageURL: nil
        ).padding().previewLayout(.sizeThatFits).preferredColorScheme(.dark)
    }
}
