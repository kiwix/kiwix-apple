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
import CoreImage

struct QRCode {

    static func image(from text: String) -> Image? {
        let data = Data(text.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            debugPrint("cannot create CIFilter")
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        
        let context = CIContext()
        let transform = CGAffineTransform(scaleX: 20, y: 20)
        guard let outputImage = filter.outputImage?.transformed(by: transform),
              let image = context.createCGImage(outputImage, from: outputImage.extent) else {
            debugPrint("cannot create qr code image")
            return nil
        }
        return Image(image, scale: 1, label: Text(text))
    }

}
