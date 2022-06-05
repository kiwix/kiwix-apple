//
//  Welcome.swift
//  Kiwix
//
//  Created by Chris Li on 6/4/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Welcome: View {
    @Binding var url: URL?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: NSPredicate(format: "fileURLBookmark != nil"),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        if zimFiles.isEmpty {
            
        } else {
            GeometryReader { proxy in
                ScrollView {
                    LazyVGrid(
                        columns: ([GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 12)]),
                        alignment: .leading,
                        spacing: 12
                    ) {
                        Section {
                            ForEach(zimFiles) { zimFile in
                                Button {
                                    url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID)
                                } label: {
                                    ZimFileCell(zimFile, prominent: .title)
                                }
                            }
                        } header: {
                            Text("Main Page").font(.title3).fontWeight(.semibold)
                        }
                    }.padding()
                }
            }
        }
    }
}

struct Welcome_Previews: PreviewProvider {
    static var previews: some View {
        Welcome(url: .constant(nil))
    }
}
