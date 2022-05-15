//
//  ZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/15/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFilesOpened: View {
    var body: some View {
        Text("Hello, World!").toolbar {
            FileImportButton()
        }
    }
}

struct ZimFilesOpened_Previews: PreviewProvider {
    static var previews: some View {
        ZimFilesOpened()
    }
}
