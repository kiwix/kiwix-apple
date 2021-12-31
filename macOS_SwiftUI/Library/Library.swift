//
//  Library.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Library: View {
    @SectionedFetchRequest(
        sectionIdentifier: \.name,
        sortDescriptors: [SortDescriptor(\.name), SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "category == %@ AND languageCode == %@", "wikipedia", "en")
    ) private var zimFiles: SectionedFetchResults<String, ZimFile>
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 12)],
                alignment: HorizontalAlignment.leading,
                spacing: 12,
                pinnedViews: [.sectionHeaders]
            ) {
                ForEach(zimFiles) { section in
                    Section {
                        ForEach(section) { zimFile in
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(zimFile.size.formatted(.byteCount(style: .file)))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("\(zimFile.articleCount.formatted(.number.notation(.compactName))) articles")
                                            .font(.caption)
                                        Text(zimFile.created.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        if let tag = zimFile.tag {
                                            ZimFileTag(string: tag)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.down.to.line.circle.fill")
                                    }
                                }
                            }.frame(maxHeight: .infinity)
                            .padding(12)
                            .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    } header: {
                        LibrarySectionHeader(title: section.id)
                            .padding(.top, 12)
                            .padding(.bottom, -2)
                    }
                }
            }.padding()
        }.task { try? await Database.shared.refreshOnlineZimFileCatalog() }
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}
