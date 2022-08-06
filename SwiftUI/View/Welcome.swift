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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.created, ascending: true)],
        animation: .easeInOut
    ) private var bookmarks: FetchedResults<Bookmark>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var selectedZimFile: ZimFile?
    
    var body: some View {
        if zimFiles.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image("Kiwix_logo_v3")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .padding(2)
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.white))
                    Text("Kiwix").font(.largeTitle).fontWeight(.bold)
                }
                Divider()
                Text("Quick start:").font(.headline)
                Button("Open") {
                    
                }.buttonStyle(.borderedProminent)
                Spacer()
            }.padding(50)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    Section {
                        ForEach(zimFiles) { zimFile in
                            Button {
                                url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID)
                            } label: {
                                ZimFileCell(zimFile, prominent: .name)
                            }
                            .buttonStyle(.plain)
                            .modifier(ZimFileContextMenu(selected: $selectedZimFile, zimFile: zimFile))
                        }
                    } header: {
                        Text("Main Page").font(.title3).fontWeight(.semibold)
                    }
                    Section {
                        ForEach(bookmarks) { bookmark in
                            Button { url = bookmark.articleURL } label: {
                                ArticleCell(bookmark: bookmark).frame(height: bookmarkItemHeight)
                            }.buttonStyle(.plain)
                        }
                    } header: {
                        Text("Bookmarks").font(.title3).fontWeight(.semibold)
                    }
                }.padding()
            }
            .sheet(item: $selectedZimFile) { zimFile in
                NavigationView {
                    ZimFileDetail(zimFile: zimFile)
                }
            }
        }
    }
    
    private var bookmarkItemHeight: CGFloat? {
        #if os(macOS)
        82
        #elseif os(iOS)
        horizontalSizeClass == .regular ? 110: nil
        #endif
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Welcome(url: .constant(nil)).preferredColorScheme(.light).padding()
        Welcome(url: .constant(nil)).preferredColorScheme(.dark).padding()
    }
}
