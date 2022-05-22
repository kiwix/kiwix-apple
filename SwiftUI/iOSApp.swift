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
class AppDelegate: UIResponder, UIApplicationDelegate { }

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UINavigationController(rootViewController: ReaderViewController())
        window?.makeKeyAndVisible()
    }
}

class ReaderViewController: UIHostingController<Reader>, UISearchControllerDelegate {
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
        if viewModel.isSearchActive {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { viewModel.cancelSearch?()}
                }
            }
        } else if horizontalSizeClass == .regular {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button { } label: { Image(systemName: "chevron.left") }
                    Button { } label: { Image(systemName: "chevron.right") }
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
                        Button { } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        Button { } label: { Image(systemName: "chevron.right") }
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
    
    var content: some View {
        Group {
            if url == nil {
                List {
                    Text("Welcome!")
                    Text("Zim File 1")
                    Text("Zim File 2")
                    Text("Zim File 3")
                }
            } else {
                WebView(url: $url)
            }
        }
        .sheet(isPresented: $isPresentingLibrary) {
            Library().environment(\.managedObjectContext, Database.shared.container.viewContext)
        }
    }
}
