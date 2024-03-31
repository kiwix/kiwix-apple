/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

import SwiftUI

import Defaults

/// A grid of zim files that are newly available.
struct ZimFilesNew: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var viewModel: LibraryViewModel
    @Default(.libraryLanguageCodes) private var languageCodes
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ZimFile.created, ascending: false),
            NSSortDescriptor(keyPath: \ZimFile.name, ascending: true),
            NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
        ],
        predicate: ZimFilesNew.buildPredicate(searchText: ""),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var searchText = ""
    
    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(zimFiles) { zimFile in
                ZimFileCell(zimFile, prominent: .name)
                    .modifier(LibraryZimFileContext(zimFile: zimFile))
            }
        }
        .modifier(GridCommon())
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(NavigationItem.new.name)
        .searchable(text: $searchText)
        .onAppear {
            viewModel.start(isUserInitiated: false)
        }
        .onChange(of: languageCodes) { _ in
            zimFiles.nsPredicate = ZimFilesNew.buildPredicate(searchText: searchText)
        }
        .onChange(of: searchText) { searchText in
            zimFiles.nsPredicate = ZimFilesNew.buildPredicate(searchText: searchText)
        }
        .overlay {
            if zimFiles.isEmpty {
                Message(text: "zim_file_new_overlay.empty".localized)
            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                if #unavailable(iOS 16), horizontalSizeClass == .regular {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label("zim_file_opened.toolbar.show_sidebar.label".localized,
                              systemImage: "sidebar.left")
                    }
                }
            }
            #endif
            ToolbarItem {
                if viewModel.state == .inProgress {
                    ProgressView()
                    #if os(macOS)
                        .scaleEffect(0.5)
                    #endif
                } else {
                    Button {
                        viewModel.start(isUserInitiated: true)
                    } label: {
                        Label("zim_file_new_button_refresh".localized,
                              systemImage: "arrow.triangle.2.circlepath.circle")
                    }
                }
            }
        }
    }
    
    private static func buildPredicate(searchText: String) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes]),
            NSPredicate(format: "requiresServiceWorkers == false")
        ]
        if let aMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
            predicates.append(NSPredicate(format: "created > %@", aMonthAgo as CVarArg))
        }
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

@available(macOS 13.0, iOS 16.0, *)
struct ZimFilesNew_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ZimFilesNew()
                .environmentObject(LibraryViewModel())
                .environment(\.managedObjectContext, Database.viewContext)
        }
    }
}
