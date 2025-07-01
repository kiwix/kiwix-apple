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

#if os(iOS)
import CoreData
import SwiftUI
import UIKit

final class SidebarViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    private lazy var dataSource = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, MenuItem> {
            [unowned self] cell, indexPath, item in
            configureCell(cell: cell, indexPath: indexPath, item: item)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [unowned self] headerView, elementKind, indexPath in
            configureHeader(headerView: headerView, elementKind: elementKind, indexPath: indexPath)
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, MenuItem>(collectionView: collectionView) {
            collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }()
    private let fetchedResultController = NSFetchedResultsController(
        fetchRequest: Tab.fetchRequest(sortDescriptors: [NSSortDescriptor(key: "created", ascending: false)]),
        managedObjectContext: Database.shared.viewContext,
        sectionNameKeyPath: nil,
        cacheName: nil
    )

    private var navigationViewModel: NavigationViewModel? {
        (splitViewController as? SplitViewController)?.navigationViewModel
    }

    enum Section: String, CaseIterable {
        case tabs
        case primary
        case library
        case settings
        case hotspot
        case donation

        static var allSections: [Section] {
            switch (FeatureFlags.hasLibrary, Brand.hideDonation) {
            case (true, true):
                allCases.filter { ![.donation].contains($0) }
            case (false, true):
                allCases.filter { ![.donation, .library, .hotspot].contains($0) }
            case (true, false):
                allCases
            case (false, false):
                allCases.filter { ![.library, .hotspot].contains($0) }
            }
        }
    }

    init() {
        super.init(collectionViewLayout: UICollectionViewLayout())
        collectionView.accessibilityIdentifier = "sidebar_collection_view"
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout { _, layoutEnvironment in
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
        guard let navigationViewModel,
              let currentItem = navigationViewModel.currentItem,
              let currentMenuItem = MenuItem(from: currentItem),
              let indexPath = dataSource.indexPath(for: currentMenuItem),
              collectionView.indexPathsForSelectedItems?.first != indexPath else { return }
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchedResultController.delegate = self

        // configure view
        navigationItem.title = Brand.appName
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.square"),
            primaryAction: UIAction { [unowned self] _ in
                navigationViewModel?.createTab()
            },
            menu: UIMenu(children: [
                UIAction(
                    title: LocalString.sidebar_view_navigation_button_close,
                    image: UIImage(systemName: "xmark.square"),
                    attributes: .destructive
                ) { [unowned self] _ in
                    guard let navigationViewModel,
                          case let .tab(tabID) = navigationViewModel.currentItem else { return }
                    navigationViewModel.deleteTab(tabID: tabID)
                },
                UIAction(
                    title: LocalString.sidebar_view_navigation_button_close_all,
                    image: UIImage(systemName: "xmark.square.fill"),
                    attributes: .destructive
                ) { [unowned self] _ in
                    navigationViewModel?.deleteAllTabs()
                }
            ])
        )

        // apply initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<Section, MenuItem>()
        snapshot.appendSections(Section.allSections)
        if snapshot.sectionIdentifiers.contains(.primary) {
            snapshot.appendItems([.bookmarks], toSection: .primary)
        }
        if snapshot.sectionIdentifiers.contains(.library) {
            snapshot.appendItems([.opened, .categories, .downloads, .new], toSection: .library)
        }
        if snapshot.sectionIdentifiers.contains(.hotspot) {
            snapshot.appendItems([.hotspot], toSection: .hotspot)
        }
        if snapshot.sectionIdentifiers.contains(.settings) {
            snapshot.appendItems([.settings], toSection: .settings)
        }
        
        // show the donation async
        Task { @MainActor in
            if snapshot.sectionIdentifiers.contains(.donation),
               await Payment.paymentButtonTypeAsync() != nil {
                snapshot.appendItems([.donation], toSection: .donation)
            }
            await dataSource.apply(snapshot, animatingDifferences: false)
            try? fetchedResultController.performFetch()
        }
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

    nonisolated func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        let tabIds = snapshot.itemIdentifiers
            .compactMap { $0 as? NSManagedObjectID }
        let tabs = tabIds.map { MenuItem.tab(objectID: $0) }
        var tabsSnapshot = NSDiffableDataSourceSectionSnapshot<MenuItem>()
        tabsSnapshot.append(tabs)
        Task { [tabsSnapshot] in
            await MainActor.run { [tabsSnapshot] in
                dataSource.apply(
                    tabsSnapshot,
                    to: .tabs,
                    animatingDifferences: dataSource.snapshot(for: .tabs).items.count > 0
                ) {
                    guard let indexPath = self.collectionView.indexPathsForSelectedItems?.first,
                          let item = self.dataSource.itemIdentifier(for: indexPath),
                          case .tab = item else { return }
                    var sourceSnapshot = self.dataSource.snapshot()
                    sourceSnapshot.reconfigureItems([item])
                    self.dataSource.apply(sourceSnapshot, animatingDifferences: true)
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard dataSource.itemIdentifier(for: indexPath) != .donation else {
            // trigger the donation pop-up, but do not select the menu item itself
            NotificationCenter.openDonations()
            return false
        }
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let splitViewController,
              let navigationViewModel,
              let navigationItem = dataSource.itemIdentifier(for: indexPath)?.navigationItem else { return }
        if navigationViewModel.currentItem != navigationItem {
            navigationViewModel.currentItem = navigationItem
        }
        if splitViewController.displayMode == .oneOverSecondary {
            splitViewController.hide(.primary)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    // MARK: - Collection View Configuration

    private func configureCell(cell: UICollectionViewListCell, indexPath: IndexPath, item: MenuItem) {
        if case let .tab(objectID) = item,
            let tab = try? Database.shared.viewContext.existingObject(with: objectID) as? Tab {
            var config = cell.defaultContentConfiguration()
            config.text = tab.title ?? LocalString.common_tab_menu_new_tab
            if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
                config.textProperties.numberOfLines = 1
                if let imgData = zimFile.faviconData {
                    config.image = UIImage(data: imgData)
                } else {
                    config.image = UIImage(named: category.icon)
                }
                config.imageProperties.maximumSize = CGSize(width: 22, height: 22)
                config.imageProperties.cornerRadius = 3
            } else {
                config.image = UIImage(systemName: "square")
            }
            cell.contentConfiguration = config
        } else {
            var config = cell.defaultContentConfiguration()
            config.text = item.name
            config.image = UIImage(systemName: item.icon)
            config.imageProperties.tintColor = item.iconForegroundColor
            cell.contentConfiguration = config
            cell.accessibilityIdentifier = item.accessibilityIdentifier
        }
    }

    private func configureHeader(headerView: UICollectionViewListCell, elementKind: String, indexPath: IndexPath) {
        guard Section.allSections.indices.contains(indexPath.section) else {
            headerView.contentConfiguration = nil
            return
        }
        let section = Section.allSections[indexPath.section]
        switch section {
        case .tabs:
            var config = UIListContentConfiguration.sidebarHeader()
            config.text = LocalString.common_tab_navigation_title
            headerView.contentConfiguration = config
        case .library:
            var config = UIListContentConfiguration.sidebarHeader()
            config.text = LocalString.common_tab_menu_library
            headerView.contentConfiguration = config
        default:
            headerView.contentConfiguration = nil
        }
    }

    private func configureSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let navigationViewModel,
              let item = dataSource.itemIdentifier(for: indexPath),
              case let .tab(tabID) = item else { return nil }
        let title = LocalString.sidebar_view_navigation_button_close
        let action = UIContextualAction(style: .destructive,
                                        title: title) { [weak navigationViewModel] _, _, _ in
            navigationViewModel?.deleteTab(tabID: tabID)
        }
        action.image = UIImage(systemName: "xmark")
        return UISwipeActionsConfiguration(actions: [action])
    }
}
#endif
