//
//  SidebarViewController.swift
//  Kiwix
//
//  Created by Chris Li on 6/12/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

#if os(iOS)
import CoreData
import UIKit

class SidebarViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    private lazy var dataSource = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, NavigationItem> {
            [unowned self] cell, indexPath, item in configureCell(cell: cell, indexPath: indexPath, item: item)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [unowned self] headerView, elementKind, indexPath in
            configureHeader(headerView: headerView, elementKind: elementKind, indexPath: indexPath)
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, NavigationItem>(collectionView: collectionView) {
            collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }()
    private let fetchedResultController = NSFetchedResultsController(
        fetchRequest: Tab.fetchRequest(sortDescriptors: [NSSortDescriptor(key: "created", ascending: false)]),
        managedObjectContext: Database.viewContext,
        sectionNameKeyPath: nil,
        cacheName: nil
    )
    
    enum Section: String, CaseIterable {
        case primary
        case tabs
        case library
        case settings
    }
    
    convenience init() {
        self.init(collectionViewLayout: UICollectionViewLayout())
        var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
        config.headerMode = .supplementary
        config.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
            configureSwipeAction(indexPath: indexPath)
        }
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchedResultController.delegate = self
        
        // configure view
        navigationItem.title = "Kiwix"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "New Tab",
            image: UIImage(systemName: "plus.square"),
            primaryAction: UIAction { [unowned self] _ in
                guard let splitViewController = splitViewController as? SplitViewController else { return }
                Task { await splitViewController.createTab() }
            },
            menu: UIMenu(children: [
                UIAction(
                    title: "Close All Tabs", image: UIImage(systemName: "xmark.square.fill"), attributes: .destructive
                ) { [unowned self] _ in
                    guard let splitViewController = splitViewController as? SplitViewController else { return }
                    Task { await splitViewController.deleteAllTabs() }
                }
            ])
        )
        
        // apply initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<Section, NavigationItem>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.bookmarks], toSection: .primary)
        snapshot.appendItems([.opened, .categories, .downloads, .new], toSection: .library)
        snapshot.appendItems([.settings], toSection: .settings)
        dataSource.apply(snapshot, animatingDifferences: false)
        try? fetchedResultController.performFetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        updateSelection()
    }
    
    /// Make sure the selected navigation item is selected and is the only cell that's selected
    private func updateSelection() {
        guard let selectedNavigationItem = (splitViewController as? SplitViewController)?.selectedNavigationItem,
              let expectedIndexPath = dataSource.indexPath(for: selectedNavigationItem) else { return }
        if let actualIndexPath = collectionView.indexPathsForSelectedItems?.first,
           expectedIndexPath != actualIndexPath {
            self.collectionView.deselectItem(at: actualIndexPath, animated: true)
            self.collectionView.selectItem(at: expectedIndexPath, animated: true, scrollPosition: [])
        } else {
            self.collectionView.selectItem(at: expectedIndexPath, animated: true, scrollPosition: [])
        }
    }
    
    /// When a tab is selected, reload it to refresh title and icon
    private func reloadSelectedTab() {
        guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
              let item = dataSource.itemIdentifier(for: indexPath),
              case .tab = item else { return }
        var snapshot = self.dataSource.snapshot()
        snapshot.reconfigureItems([item])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Delegate
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let tabs = snapshot.itemIdentifiers
            .compactMap { $0 as? NSManagedObjectID }
            .map { NavigationItem.tab(objectID: $0) }
        var snapshot = NSDiffableDataSourceSectionSnapshot<NavigationItem>()
        snapshot.append(tabs)
        dataSource.apply(snapshot, to: .tabs, animatingDifferences: true) {
            self.updateSelection()
            self.reloadSelectedTab()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // deselect all other navigation items
        collectionView.indexPathsForSelectedItems?.filter {$0 != indexPath}.forEach { indexPath in
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        
        // navigation to the selected navigation item
        guard let splitViewController = splitViewController as? SplitViewController,
              let navigationItem = dataSource.itemIdentifier(for: indexPath) else { return }
        splitViewController.navigateTo(navigationItem)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        false
    }
    
    // MARK: - Configuration
    
    private func configureCell(cell: UICollectionViewListCell, indexPath: IndexPath, item: NavigationItem) {
        var config = cell.defaultContentConfiguration()
        if case let .tab(objectID) = item, let tab = try? Database.viewContext.existingObject(with: objectID) as? Tab {
            config.text = tab.title ?? item.name
            config.image = UIImage(systemName: item.icon)
        } else {
            config.text = item.name
            config.image = UIImage(systemName: item.icon)
        }
        cell.contentConfiguration = config
    }
    
    private func configureHeader(headerView: UICollectionViewListCell, elementKind: String, indexPath: IndexPath) {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .tabs:
            var config = UIListContentConfiguration.sidebarHeader()
            config.text = "Tabs"
            headerView.contentConfiguration = config
        case .library:
            var config = UIListContentConfiguration.sidebarHeader()
            config.text = "Library"
            headerView.contentConfiguration = config
        default:
            headerView.contentConfiguration = nil
        }
    }
    
    private func configureSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = self.dataSource.itemIdentifier(for: indexPath),
              case let .tab(objectID) = item else { return nil }
        let action = UIContextualAction(style: .destructive, title: "Close") { [unowned self] _, _, _ in
            guard let splitViewController = splitViewController as? SplitViewController else { return }
            Task { await splitViewController.deleteTab(objectID: objectID) }
        }
        action.image = UIImage(systemName: "xmark")
        return UISwipeActionsConfiguration(actions: [action])
    }
}
#endif
