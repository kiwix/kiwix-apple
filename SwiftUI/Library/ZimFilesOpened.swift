//
//  ZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/15/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFilesOpened: View {
    @State private var isShowingFileImporter: Bool = false
    
    var body: some View {
        Text("Hello, World!").toolbar {
            Button {
                isShowingFileImporter = true
            } label: {
                Image(systemName: "plus")
            }
        }.modifier(FileImportModifier(isShowing: $isShowingFileImporter))
    }
}

struct ZimFilesOpened_Previews: PreviewProvider {
    static var previews: some View {
        ZimFilesOpened()
    }
}
