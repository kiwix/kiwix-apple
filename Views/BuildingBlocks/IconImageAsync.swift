// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI

struct IconImageAsync: View {
    private static let fallback: Image = Image(systemName: "square")
    let tab: Tab
    @State private var image: Image = Self.fallback
    
    var body: some View {
        image
            .resizable()
            .frame(maxWidth: 22, maxHeight: 22)
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 3, height: 3)))
            .task(priority: .utility) {
                image = await iconImage()
            }
    }
    
    private func iconImage() async -> Image {
        let categoryImage: UIImage?
        if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
            if let imgData = zimFile.faviconData,
               let image = UIImage(data: imgData) {
                categoryImage = image
            } else {
                categoryImage = UIImage(named: category.icon)
            }
        } else {
            categoryImage = nil
        }
        
        if let categoryImage {
            return Image(uiImage: categoryImage)
        } else {
            return Self.fallback
        }
    }
}
