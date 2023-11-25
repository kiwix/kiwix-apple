//
//  SidebarViewController.swift
//  Kiwix
//
//  Created by Chris Li on 9/4/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

#if os(iOS)
import CoreData
import SwiftUI
import UIKit

class SidebarViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    private lazy var dataSource = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, NavigationItem> {
            [unowned self] cell, indexPath, item in
            configureCell(cell: cell, indexPath: indexPath, item: item)
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

        static var allSections: [Section] {
            if FeatureFlags.hasLibrary {
                allCases
            } else {
                allCases.filter { $0 != .library }
            }
        }
    }
    
    init() {
        super.init(collectionViewLayout: UICollectionViewLayout())
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = .supplementary
            config.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
                configureSwipeAction(indexPath: indexPath)
            }
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
            return section
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateSelection() {
        guard let splitViewController = splitViewController as? SplitViewController,
              let currentItem = splitViewController.navigationViewModel.currentItem,
              let indexPath = dataSource.indexPath(for: currentItem),
              collectionView.indexPathsForSelectedItems?.first != indexPath else { return }
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchedResultController.delegate = self
        
        // configure view
        navigationItem.title = Brand.appName
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.square"),
            primaryAction: UIAction { [unowned self] _ in
                guard let splitViewController = splitViewController as? SplitViewController else { return }
                splitViewController.navigationViewModel.createTab()
            },
            menu: UIMenu(children: [
                UIAction(
                    title: "Close This Tab".localized,
                    image: UIImage(systemName: "xmark.square"),
                    attributes: .destructive
                ) { [unowned self] _ in
                    guard let splitViewController = splitViewController as? SplitViewController,
                          case let .tab(tabID) = splitViewController.navigationViewModel.currentItem else { return }
                    splitViewController.navigationViewModel.deleteTab(tabID: tabID)
                },
                UIAction(
                    title: "Close All Tabs".localized,
                    image: UIImage(systemName: "xmark.square.fill"),
                    attributes: .destructive
                ) { [unowned self] _ in
                    guard let splitViewController = splitViewController as? SplitViewController else { return }
                    splitViewController.navigationViewModel.deleteAllTabs()
                }
            ])
        )
        
        // apply initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<Section, NavigationItem>()
        snapshot.appendSections(Section.allSections)
        snapshot.appendItems([.bookmarks], toSection: .primary)
        if FeatureFlags.hasLibrary {
            snapshot.appendItems([.opened, .categories, .downloads, .new], toSection: .library)
        }
        snapshot.appendItems([.settings], toSection: .settings)
        dataSource.apply(snapshot, animatingDifferences: false)
        try? fetchedResultController.performFetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateSelection()
    }
    
    // MARK: - Delegations
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let tabs = snapshot.itemIdentifiers
            .compactMap { $0 as? NSManagedObjectID }
            .map { NavigationItem.tab(objectID: $0) }
        var snapshot = NSDiffableDataSourceSectionSnapshot<NavigationItem>()
        snapshot.append(tabs)
        dataSource.apply(snapshot, to: .tabs, animatingDifferences: dataSource.snapshot(for: .tabs).items.count > 0) {
            // [iOS 15] when a tab is selected, reload it to refresh title and icon
            guard #unavailable(iOS 16),
                  let indexPath = self.collectionView.indexPathsForSelectedItems?.first,
                  let item = self.dataSource.itemIdentifier(for: indexPath),
                  case .tab = item else { return }
            var snapshot = self.dataSource.snapshot()
            snapshot.reconfigureItems([item])
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let splitViewController = splitViewController as? SplitViewController,
              let navigationItem = dataSource.itemIdentifier(for: indexPath) else { return }
        splitViewController.navigationViewModel.currentItem = navigationItem
        if splitViewController.displayMode == .oneOverSecondary {
            splitViewController.hide(.primary)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // MARK: - Collection View Configuration
    
    private func configureCell(cell: UICollectionViewListCell, indexPath: IndexPath, item: NavigationItem) {
        if case let .tab(objectID) = item, let tab = try? Database.viewContext.existingObject(with: objectID) as? Tab {
            if #available(iOS 16.0, *) {
                cell.contentConfiguration = UIHostingConfiguration {
                    TabLabel(tab: tab)
                }
            } else {
                var config = cell.defaultContentConfiguration()
                config.text = tab.title ?? item.name
                config.textProperties.numberOfLines = 1
                config.image = UIImage(systemName: item.icon)
                cell.contentConfiguration = config
            }
        } else {
            var config = cell.defaultContentConfiguration()
            config.text = item.name
            config.image = UIImage(systemName: item.icon)
            cell.contentConfiguration = config
        }
        
    }
    
    private func configureHeader(headerView: UICollectionViewListCell, elementKind: String, indexPath: IndexPath) {
        let section = Section.allSections[indexPath.section]
        switch section {
        case .tabs:
            var config = UIListContentConfiguration.sidebarHeader()
            config.text = "Tabs".localized
            headerView.contentConfiguration = config
        case .library:
            var config = UIListContentConfiguration.sidebarHeader()
            config.text = "Library".localized
            headerView.contentConfiguration = config
        default:
            headerView.contentConfiguration = nil
        }
    }
    
    private func configureSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let splitViewController = splitViewController as? SplitViewController,
              let item = dataSource.itemIdentifier(for: indexPath),
              case let .tab(tabID) = item else { return nil }
        let action = UIContextualAction(style: .destructive, title: "Close".localized) { _, _, _ in
            splitViewController.navigationViewModel.deleteTab(tabID: tabID)
        }
        action.image = UIImage(systemName: "xmark")
        return UISwipeActionsConfiguration(actions: [action])
    }
}
#endif
