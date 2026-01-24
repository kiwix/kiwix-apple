// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI
import Defaults

private final class ViewModel: ObservableObject {
    
    @Published private(set) var zimFiles: [ZimFile] = []
    
    private var languageCodes = Set<String>()
    private var searchText: String = ""
    
    private let sortDescriptors = [
        NSSortDescriptor(keyPath: \ZimFile.created, ascending: false),
        NSSortDescriptor(keyPath: \ZimFile.name, ascending: true),
        NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
    ]
    
    func update(languageCodes: Set<String>) {
        guard languageCodes != self.languageCodes else { return }
        self.languageCodes = languageCodes
        Task {
            await update()
        }
    }
    
    func update(searchText: String) {
        guard searchText != self.searchText else { return }
        self.searchText = searchText
        Task {
            await update()
        }
    }
    
    @MainActor
    func update() async {
        let searchText = self.searchText
        let languageCodes = self.languageCodes
        let newZimFiles: [ZimFile] = await withCheckedContinuation { continuation in
            Database.shared.performBackgroundTask { context in
                let predicate: NSPredicate = Self.buildPredicate(
                    searchText: searchText,
                    languageCodes: languageCodes
                )
                if let results = try? context.fetch(
                    ZimFile.fetchRequest(
                        predicate: predicate,
                        sortDescriptors: self.sortDescriptors
                    )
                ) {
                    continuation.resume(returning: results)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
        withAnimation(.easeInOut) {
            self.zimFiles = newZimFiles
        }
    }
    
    private static func buildPredicate(searchText: String, languageCodes: Set<String>) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "languageCode IN %@", languageCodes),
            NSPredicate(format: "requiresServiceWorkers == false")
        ]
        if let aMonthAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) {
            predicates.append(NSPredicate(format: "created > %@", aMonthAgo as CVarArg))
        }
        if !searchText.isEmpty {
            predicates.append(
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "name CONTAINS[cd] %@", searchText),
                    NSPredicate(format: "fileDescription CONTAINS[cd] %@", searchText)
                ])
            )
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
}

/// A grid of zim files that are newly available.
struct ZimFilesNew: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var selection: SelectedZimFileViewModel
    @EnvironmentObject var library: LibraryViewModel
    @Default(.libraryLanguageCodes) private var languageCodes
    @StateObject private var viewModel = ViewModel()
    @State private var searchText = ""
    let dismiss: (() -> Void)? // iOS only

    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(viewModel.zimFiles, id: \.fileID) { zimFile in
                LibraryZimFileContext(
                    content: {
                        ZimFileCell(
                            zimFile,
                            prominent: .name,
                            isSelected: selection.isSelected(zimFile)
                        )
                    },
                    zimFile: zimFile,
                    selection: selection,
                    dismiss: dismiss)
                .transition(AnyTransition.opacity)
            }
        }
        .modifier(GridCommon())
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(MenuItem.new.name)
        .searchable(text: $searchText, prompt: LocalString.common_search)
        .onAppear {
            viewModel.update(searchText: searchText)
            viewModel.update(languageCodes: languageCodes)
            library.start(isUserInitiated: false)
        }
        .onChange(of: searchText) { _, newSearchText in
            viewModel.update(searchText: newSearchText)
        }
        .onChange(of: languageCodes) { _, newLanguageCodes in
            viewModel.update(languageCodes: newLanguageCodes)
        }
        .overlay {
            if viewModel.zimFiles.isEmpty {
                switch library.state {
                case .inProgress:
                    Message(text: LocalString.zim_file_catalog_fetching_message)
                case .error:
                    Message(text: LocalString.library_refresh_error_retrieve_description, color: .red)
                case .initial, .complete:
                    Message(text: LocalString.zim_file_new_overlay_empty)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                if library.state == .inProgress {
                    ProgressView()
                    #if os(macOS)
                        .scaleEffect(0.5)
                    #endif
                } else {
                    Button {
                        library.start(isUserInitiated: true)
                    } label: {
                        Label(LocalString.zim_file_new_button_refresh,
                              systemImage: "arrow.triangle.2.circlepath.circle")
                    }
                }
            }
        }
    }
}

struct ZimFilesNew_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ZimFilesNew(dismiss: nil)
                .environmentObject(LibraryViewModel())
                .environment(\.managedObjectContext, Database.shared.viewContext)
        }
    }
}
