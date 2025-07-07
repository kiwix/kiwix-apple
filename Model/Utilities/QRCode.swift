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
import os

struct QRCode {

    static func image(from text: String) async -> Image? {
        let data = Data(text.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            os_log("QRCode cannot create CIFilter", log: Log.LibraryService, type: .error)
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        
        let context = CIContext()
        let transform = CGAffineTransform(scaleX: 20, y: 20)
        guard let outputImage = filter.outputImage?.transformed(by: transform),
              let image = context.createCGImage(outputImage, from: outputImage.extent) else {
            os_log("QRCode cannot create image", log: Log.LibraryService, type: .error)
            return nil
        }
        return Image(image, scale: 1, label: Text(text))
    }

}
