//
//  HomeView.swift
//  Kiwix
//
//  Created by Chris Li on 9/24/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//


import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct HomeView: View {
    private let localZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
            return database.objects(ZimFile.self).filter(predicate).sorted(byKeyPath: "size", ascending: false)
        } catch { return nil }
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                    Section(header: HStack { Text("On Device").font(.title2).fontWeight(.bold); Spacer() }) {
                        ForEach(localZimFiles!.freeze(), id: \.id) { zimFile in
                            ZimFileCell(zimFile: zimFile)
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, calculateHorizontalPadding(size: geometry.size))
            }.background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
    
    private func calculateHorizontalPadding(size: CGSize) -> CGFloat {
        switch size.width {
        case 1000..<CGFloat.infinity:
            return (size.width - size.height) / 2 - 20
        case 400..<1000:
            return 20
        default:
            return 10
        }
    }
}
