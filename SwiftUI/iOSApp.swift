//
//  ViewController.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 5/21/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import UIKit
import SwiftUI


@main
struct Kiwix: App {
    init() {
        reopen()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .edgesIgnoringSafeArea(.all)
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
        }
    }
    
    private func reopen() {
        let context = Database.shared.container.viewContext
        let request = ZimFile.fetchRequest(predicate: NSPredicate(format: "fileURLBookmark != nil"))
        guard let zimFiles = try? context.fetch(request) else { return }
        zimFiles.forEach { zimFile in
            guard let data = zimFile.fileURLBookmark else { return }
            if let data = ZimFileService.shared.open(bookmark: data) {
                zimFile.fileURLBookmark = data
            }
        }
        if context.hasChanges {
            try? context.save()
        }
    }
}

private struct RootView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: RootViewController())
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }
}

private class RootViewController: UIHostingController<Reader>, UISearchControllerDelegate {
    let searchController = UISearchController()
    
    convenience init() {
        self.init(rootView: Reader())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearch()
    }
    
    private func configureSearch() {
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        searchController.hidesNavigationBarDuringPresentation = false
//        searchController.searchResultsUpdater = searchResultsController
        searchController.automaticallyShowsCancelButton = false
        searchController.showsSearchResultsController = true
        rootView.viewModel.cancelSearch = {[unowned self] in self.searchController.isActive = false }
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        rootView.viewModel.isSearchActive = true
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        rootView.viewModel.isSearchActive = false
    }
}

struct Reader: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel = ReaderViewModel()
    @State var isPresentingLibrary = false
    @State var url: URL?
    
    var body: some View {
        Group {
            if url == nil {
                List {
                    Text("Welcome!")
                    Text("Zim File 1")
                    Text("Zim File 2")
                    Text("Zim File 3")
                }
            } else {
                WebView(url: $url, webView: viewModel.webView)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .modifier(ToolbarButtons(isPresentingLibrary: $isPresentingLibrary))
        .environmentObject(viewModel)
        .onOpenURL { url in
            self.url = url
            withAnimation {
                isPresentingLibrary = false
            }
        }
        .sheet(isPresented: $isPresentingLibrary) {
            Library().environment(\.managedObjectContext, Database.shared.container.viewContext)
        }
    }
}

private struct ToolbarButtons: ViewModifier {
    @Binding var isPresentingLibrary: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var viewModel: ReaderViewModel
    
    func body(content: Content) -> some View {
        if viewModel.isSearchActive {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { viewModel.cancelSearch?()}
                }
            }
        } else if horizontalSizeClass == .regular {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    NavigateBackButton()
                    NavigateForwardButton()
                    Button { } label: { Image(systemName: "list.bullet") }
                    Button { } label: { Image(systemName: "star") }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { } label: { Image(systemName: "die.face.5") }
                    Button { } label: { Image(systemName: "house") }
                    Button { isPresentingLibrary = true } label: { Image(systemName: "folder") }
                    Button { } label: { Image(systemName: "gear") }
                }
            }
        } else {
            content.toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Group {
                        NavigateBackButton()
                        Spacer()
                        NavigateForwardButton()
                    }
                    Spacer()
                    Group {
                        Button { } label: { Image(systemName: "list.bullet") }
                        Spacer()
                        Button { } label: { Image(systemName: "star") }
                        Spacer()
                        Button { } label: { Image(systemName: "die.face.5") }
                    }
                    Spacer()
                    Menu {
                        Button { } label: { Label("Main Page", systemImage: "house") }
                        Button { isPresentingLibrary = true } label: { Label("Library", systemImage: "folder") }
                        Button { } label: { Label("Settings", systemImage: "gear") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}
