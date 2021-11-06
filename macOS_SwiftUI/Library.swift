//
//  Library.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

struct Library: View {
    @EnvironmentObject var viewModel: SceneViewModel
    @ObservedResults(
        ZimFile.self,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) private var onDevice
    
    var body: some View {
        List {
            ForEach(onDevice) { zimFile in
                Button(zimFile.title) {
                    guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else { return }
                    viewModel.action = .url(url)
                }
//                Button { zimFileSelected(zimFile.fileID, zimFile.title) } label: {
//                    ListRow(title: zimFile.title, detail: zimFile.description, faviconData: zimFile.faviconData)
//                }
            }
        }
    }
}
