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
    @State var selected: String?
    
    var body: some View {
        List(selection: $selected) {
            Section {
                ForEach(onDevice, id: \.fileID) { zimFile in
                    Text(zimFile.title)
                }
            }
        }.onChange(of: selected) { newValue in
            viewModel.loadMainPage(zimFileID: newValue)
        }
    }
}
