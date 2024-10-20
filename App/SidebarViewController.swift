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
        managedObjectContext: Database.shared.viewContext,
        sectionNameKeyPath: nil,
        cacheName: nil
    )

    private var navigationViewModel: NavigationViewModel? {
        (splitViewController as? SplitViewController)?.navigationViewModel
    }

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
        guard let navigationViewModel,
              let currentItem = navigationViewModel.currentItem,
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
                navigationViewModel?.createTab()
            },
            menu: UIMenu(children: [
                UIAction(
                    title: "sidebar_view.navigation.button.close".localized,
                    image: UIImage(systemName: "xmark.square"),
                    attributes: .destructive
                ) { [unowned self] _ in
                    guard let navigationViewModel,
                          case let .tab(tabID) = navigationViewModel.currentItem else { return }
                    navigationViewModel.deleteTab(tabID: tabID)
                },
                UIAction(
                    title: "sidebar_view.navigation.button.close_all".localized,
                    image: UIImage(systemName: "xmark.square.fill"),
                    attributes: .destructive
                ) { [unowned self] _ in
                    navigationViewModel?.deleteAllTabs()
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

    nonisolated func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        let tabs = snapshot.itemIdentifiers
            .compactMap { $0 as? NSManagedObjectID }
            .map { NavigationItem.tab(objectID: $0) }
        var snapshot = NSDiffableDataSourceSectionSnapshot<NavigationItem>()
        guard !tabs.isEmpty else {
            // make sure we do not end up with no tabs at all
            Task { @MainActor in
                // this triggers the DB, that triggers fetch results
                // and we will end up running this function again,
                // but with 1 new tab
                navigationViewModel?.createTab()
            }
            return
        }
        snapshot.append(tabs)
        Task { [snapshot] in
            await MainActor.run { [snapshot] in
                dataSource.apply(
                    snapshot,
                    to: .tabs,
                    animatingDifferences: dataSource.snapshot(for: .tabs).items.count > 0
                ) {
                    guard let indexPath = self.collectionView.indexPathsForSelectedItems?.first,
                          let item = self.dataSource.itemIdentifier(for: indexPath),
                          case .tab = item else { return }
                    var snapshot = self.dataSource.snapshot()
                    snapshot.reconfigureItems([item])
                    self.dataSource.apply(snapshot, animatingDifferences: true)
                }
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let splitViewController,
              let navigationViewModel,
              let navigationItem = dataSource.itemIdentifier(for: indexPath) else { return }
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

    private func configureCell(cell: UICollectionViewListCell, indexPath: IndexPath, item: NavigationItem) {
        if case let .tab(objectID) = item,
            let tab = try? Database.shared.viewContext.existingObject(with: objectID) as? Tab {
            var config = cell.defaultContentConfiguration()
            config.text = tab.title ?? "common.tab.menu.new_tab".localized
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
            cell.contentConfiguration = config
        }

    }

    private func configureHeader(headerView: UICollectionViewListCell, elementKind: String, indexPath: IndexPath) {
        let section = Section.allSections[indexPath.section]
        switch section {
        case .tabs:
            var config = UIListContentConfiguration.sidebarHeader()
            config.text = "common.tab.navigation.title".localized
            headerView.contentConfiguration = config
        case .library:
            var config = UIListContentConfiguration.sidebarHeader()
            config.text = "common.tab.menu.library".localized
            headerView.contentConfiguration = config
        default:
            headerView.contentConfiguration = nil
        }
    }

    private func configureSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let navigationViewModel,
              let item = dataSource.itemIdentifier(for: indexPath),
              case let .tab(tabID) = item else { return nil }
        let title = "sidebar_view.navigation.button.close".localized
        let action = UIContextualAction(style: .destructive,
                                        title: title) { [weak navigationViewModel] _, _, _ in
            navigationViewModel?.deleteTab(tabID: tabID)
        }
        action.image = UIImage(systemName: "xmark")
        return UISwipeActionsConfiguration(actions: [action])
    }
}
#endif
