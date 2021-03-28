//
//  ZimFileDetailView.swift
//  Kiwix
//
//  Created by Chris Li on 11/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

import RealmSwift

@available(iOS 14.0, *)
struct ZimFileDetailView: View {
    @StateRealmObject var zimFile = ZimFile()
    
    init(id: String) {
        if let database = try? Realm(configuration: Realm.defaultConfig),
           let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: id) {
            self.zimFile = zimFile
        }
    }
    
    init(zimFile: ZimFile) {
        self.zimFile = zimFile
    }
    
    var body: some View {
        List {
            Section {
//                TitleDetailCell(title: "ID", detail: zimFile.id.prefix(8))
            }
        }.listStyle(InsetGroupedListStyle())
    }
}

@available(iOS 14.0, *)
struct ZimFileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ZimFileDetailView(id: "")
    }
}
