//
//  CompactViewController.swift
//  Kiwix
//
//  Created by Chris Li on 6/27/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

#if os(iOS)
import CoreData
import SwiftUI
import UIKit

import SwiftUIBackports

class CompactViewController<Content>: UIHostingController<Content>, UISearchBarDelegate where Content: View{
    private let searchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // configure search
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.titleView = searchController.searchBar
        navigationController?.isToolbarHidden = false
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        guard traitCollection.horizontalSizeClass == .compact,
              UIDevice.current.userInterfaceIdiom == .pad else { return }
        navigationItem.setRightBarButton(
            UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [unowned self] _ in
                searchBar.resignFirstResponder()
                navigationItem.rightBarButtonItem = nil
            }), animated: true
        )
    }
}

struct CompactView: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    
    var body: some View {
        Group {
            WebView().ignoresSafeArea().id(viewModel.tabID)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationButtons()
                Spacer()
                OutlineButton()
                Spacer()
                BookmarkButton()
                Spacer()
                RandomArticleButton()
                Spacer()
                TabsManagerButton()
            }
        }
    }
}

private struct TabsManagerButton: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var presentedSheet: PresentedSheet?
    
    enum PresentedSheet: String, Identifiable {
        var id: String { rawValue }
        case library, tabsManager
    }
    
    var body: some View {
        Menu {
            Section {
                ForEach(zimFiles) { zimFile in
                    Button {
                        viewModel.loadMainArticle(zimFileID: zimFile.fileID)
                    } label: { Label(zimFile.name, systemImage: "house") }
                }
            }
            Section {
                Button {
                    presentedSheet = .library
                } label: {
                    Label("Library", systemImage: "folder")
                }
            }
        } label: {
            Label("Tabs Manager", systemImage: "square.stack")
        } primaryAction: {
            presentedSheet = .tabsManager
        }.sheet(item: $presentedSheet) { presentedSheet in
            switch presentedSheet {
            case .library:
                Library()
            case .tabsManager:
                TabsManager().ignoresSafeArea().modify { view in
                    if #available(iOS 16.0, *) {
                        view.presentationDetents([.medium, .large])
                    } else {
                        /*
                         HACK: Use medium as selection so that half sized sheets are consistently shown
                         when tab manager button is pressed, user can still freely adjust sheet size.
                        */
                        view.backport.presentationDetents([.medium, .large], selection: .constant(.medium))
                    }
                }
            }
        }
    }
}

// MARK: - Tabs Management

struct TabsManager: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: TabsManagerViewController())
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }
}

private class TabsManagerViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    private lazy var dataSource = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, NSManagedObjectID> {
            [unowned self] cell, indexPath, item in configureCell(cell: cell, indexPath: indexPath, objectID: item)
        }
        return UICollectionViewDiffableDataSource<Section, NSManagedObjectID>(collectionView: collectionView) {
            collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }()
    private let fetchedResultController = NSFetchedResultsController(
        fetchRequest: Tab.fetchRequest(sortDescriptors: [NSSortDescriptor(key: "created", ascending: false)]),
        managedObjectContext: Database.viewContext,
        sectionNameKeyPath: nil,
        cacheName: nil
    )
    
    enum Section {
        case main
    }
    
    convenience init() {
        self.init(collectionViewLayout: UICollectionViewLayout())
        var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
        config.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
            configureSwipeAction(indexPath: indexPath)
        }
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchedResultController.delegate = self

        // configure navigation bar
        navigationItem.title = "Tabs"
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction {
            [unowned self] _ in self.dismiss(animated: true)
        })
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "New Tab",
            image: UIImage(systemName: "plus.square"),
            primaryAction: UIAction { [unowned self] _ in
                guard let splitViewController = presentingViewController as? SplitViewController else { return }
                Task {
                    await splitViewController.createTab()
                    self.dismiss(animated: true)
                }
            },
            menu: UIMenu(children: [
                UIAction(
                    title: "Close All Tabs", image: UIImage(systemName: "xmark.square.fill"), attributes: .destructive
                ) { [unowned self] _ in
                    guard let splitViewController = presentingViewController as? SplitViewController else { return }
                    Task { await splitViewController.deleteAllTabs() }
                }
            ])
        )

        // apply initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>()
        snapshot.appendSections([.main])
        dataSource.apply(snapshot, animatingDifferences: false)
        try? fetchedResultController.performFetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSelection()
    }
    
    /// Make sure the selected navigation item is selected and is the only cell that's selected
    private func updateSelection() {
        guard let selectedNavigationItem = (presentingViewController as? SplitViewController)?.selectedNavigationItem,
              case let .tab(objectID) = selectedNavigationItem,
              let expectedIndexPath = dataSource.indexPath(for: objectID) else { return }
        if let actualIndexPath = collectionView.indexPathsForSelectedItems?.first,
           expectedIndexPath != actualIndexPath {
            self.collectionView.deselectItem(at: actualIndexPath, animated: true)
            self.collectionView.selectItem(at: expectedIndexPath, animated: true, scrollPosition: [])
        } else {
            self.collectionView.selectItem(at: expectedIndexPath, animated: true, scrollPosition: [])
        }
    }
    
    // MARK: Delegations
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        dataSource.apply(
            snapshot as NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>,
            animatingDifferences: true
        ) { self.updateSelection() }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let splitViewController = presentingViewController as? SplitViewController,
              let objectID = dataSource.itemIdentifier(for: indexPath) else { return }
        splitViewController.navigateTo(NavigationItem.tab(objectID: objectID))
        dismiss(animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        false
    }
    
    // MARK: Collection View Configuration
    
    private func configureCell(cell: UICollectionViewListCell, indexPath: IndexPath, objectID: NSManagedObjectID) {
        guard let tab = try? Database.viewContext.existingObject(with: objectID) as? Tab else { return }
        var config = cell.defaultContentConfiguration()
        config.text = tab.title ?? NavigationItem.tab(objectID: objectID).name
        config.image = UIImage(systemName: NavigationItem.tab(objectID: objectID).icon)
        cell.contentConfiguration = config
    }

    private func configureSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let objectID = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
        let action = UIContextualAction(style: .destructive, title: "Close") { [unowned self] _, _, _ in
            guard let splitViewController = presentingViewController as? SplitViewController else { return }
            Task { await splitViewController.deleteTab(objectID: objectID) }
        }
        action.image = UIImage(systemName: "xmark")
        return UISwipeActionsConfiguration(actions: [action])
    }
}
#endif
