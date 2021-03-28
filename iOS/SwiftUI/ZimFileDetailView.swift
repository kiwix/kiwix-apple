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
    @StateRealmObject var zimFile: ZimFile
    
    private let countFormatter = NumberFormatter()
    
    init(fileID: String) {
        if let database = try? Realm(), let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: fileID) {
            self._zimFile = StateRealmObject(wrappedValue: zimFile)
        } else {
            self._zimFile = StateRealmObject(wrappedValue: ZimFile())
        }
        countFormatter.numberStyle = .decimal
    }
    
    var body: some View {
        List {
            Section {
                TitleDetailCell(title: "Language", detail: zimFile.localizedLanguageName)
                TitleDetailCell(title: "Size", detail: zimFile.sizeDescription ?? "Unknown")
                TitleDetailCell(title: "Date", detail: zimFile.creationDateDescription ?? "Unknown")
            }
            Section {
                TitleDetailCell(title: "Picture", detail: zimFile.hasPictures ? "Yes" : "No")
                TitleDetailCell(title: "Videos", detail: zimFile.hasVideos ? "Yes" : "No")
                TitleDetailCell(title: "Details", detail: zimFile.hasDetails ? "Yes" : "No")
            }
            Section {
                TitleDetailCell(title: "Article Count", detail: formatCount(zimFile.articleCount.value))
                TitleDetailCell(title: "Media Count", detail: formatCount(zimFile.mediaCount.value))
            }
            Section {
                TitleDetailCell(title: "Creator", detail: zimFile.creator ?? "Unknown")
                TitleDetailCell(title: "Publisher", detail: zimFile.publisher ?? "Unknown")
            }
            Section {
                TitleDetailCell(title: "ID", detail: String(zimFile.fileID.prefix(8)))
            }
        }
        .navigationTitle(zimFile.title)
        .listStyle(InsetGroupedListStyle())
    }
    
    private func formatCount(_ value: Int64?) -> String {
        if let value = value, let formatted = countFormatter.string(from: NSNumber(value: value)) {
            return formatted
        } else {
            return "Unknown"
        }
    }
}
