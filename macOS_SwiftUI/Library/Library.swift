//
//  Library.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Library: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.size, order: .reverse)]
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        List(zimFiles) { zimFile in
            Text(zimFile.name)
        }.task { try? await Database.shared.refreshOnlineZimFileCatalog() }
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}
