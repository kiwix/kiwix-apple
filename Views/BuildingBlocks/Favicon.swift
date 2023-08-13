//
//  Favicon.swift
//  Kiwix
//
//  Created by Chris Li on 1/2/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Favicon: View {
    @State var imageData: Data?
    
    private let category: Category
    private let imageURL: URL?
    
    init(category: Category, imageData: Data? = nil, imageURL: URL? = nil) {
        self.category = category
        self.imageURL = imageURL
        self._imageData = State(wrappedValue: imageData)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.white.clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            image.scaledToFit().cornerRadius(2).padding(1)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard let imageURL = imageURL, imageData == nil else { return }
            Database.shared.saveImageData(url: imageURL) { data in
                imageData = data
            }
        }
    }
    
    @ViewBuilder
    var image: some View {
        #if os(macOS)
        if let data = imageData, let image = NSImage(data: data) {
            Image(nsImage: image).resizable()
        } else {
            Image(category.name).resizable()
        }
        #elseif os(iOS)
        if let data = imageData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable()
        } else {
            Image(category.name).resizable()
        }
        #endif
    }
}

@available(iOS 15.0, *)
struct Favicon_Previews: PreviewProvider {
    static var previews: some View {
        Favicon(
            category: .wikipedia,
            imageData: nil,
            imageURL: URL(
                string: "https://library.kiwix.org/meta?name=favicon&content=wikipedia_en_climate_change_maxi_2021-12"
            )!
        ).frame(width: 200, height: 200).previewLayout(.sizeThatFits)
        Favicon(
            category: .ted,
            imageData: nil,
            imageURL: nil
        ).frame(width: 200, height: 200).previewLayout(.sizeThatFits)
    }
}
