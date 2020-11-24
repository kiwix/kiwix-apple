//
//  LibraryViewController_iOS14.swift
//  Kiwix
//
//  Created by Chris Li on 11/23/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift


@available(iOS 13.0, *)
class LibraryViewController_iOS14: UIViewController {
    private let collectionView: UICollectionView
    private let dataSource: UICollectionViewDiffableDataSource<Section, ZimFile>
    
    private let onDeviceZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
            return database.objects(ZimFile.self).filter(predicate).sorted(byKeyPath: "size", ascending: false)
        } catch { return nil }
    }()
    private var onDeviceZimFilesChangeToken: NotificationToken?
    
    init() {
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        self.dataSource = UICollectionViewDiffableDataSource(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, zimFile in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ZimFileCell", for: indexPath) as! ZimFileModernCell
            cell.titleLabel.text = zimFile.title
            cell.fileNameLabel.text = "placeholder_file_name.zim"
            cell.fileSizeLabel.text = zimFile.sizeDescription
            cell.creationDateLabel.text = zimFile.creationDateDescription
            cell.articleCountLabel.text = zimFile.articleCountDescription
            return cell
        })
        super.init(nibName: nil, bundle: nil)
        dataSource.supplementaryViewProvider = nil
//            dataSource.supplementaryViewProvider = HomeController.supplementaryViewProvider
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: self.layoutSectionProvider)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = collectionView
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(ZimFileModernCell.self, forCellWithReuseIdentifier: "ZimFileCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onDeviceZimFilesChangeToken = onDeviceZimFiles?.observe({ [unowned self] changes in
            switch changes {
            case .initial(let zimFiles):
                var snapshot = dataSource.snapshot()
                if zimFiles.count > 0, snapshot.indexOfSection(.onDeviceZimFiles) == nil {
                    snapshot.appendSections([.onDeviceZimFiles])
                    snapshot.appendItems(Array(zimFiles), toSection: .onDeviceZimFiles)
                } else if zimFiles.count == 0 {
                    snapshot.deleteSections([.onDeviceZimFiles])
                }
                dataSource.apply(snapshot, animatingDifferences: false)
            case .update(let zimFiles, let deletions, let insertions, let modifications):
                var snapshot = dataSource.snapshot()
                snapshot.reloadSections([.onDeviceZimFiles])
                dataSource.apply(snapshot, animatingDifferences: true)
            default:
                break
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDeviceZimFilesChangeToken = nil
    }
    
    private func layoutSectionProvider(sectionIndex: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let itemCountPerRow: Int = environment.container.contentSize.width > 1000 ? 3 : 2
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/CGFloat(itemCountPerRow)), heightDimension: .estimated(50)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1), heightDimension: .estimated(50)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: itemCountPerRow)
        group.interItemSpacing = .fixed(10)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
//        section.boundarySupplementaryItems = [
//            NSCollectionLayoutBoundarySupplementaryItem(
//                layoutSize: NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)
//                ),
//                elementKind: "SectionHeaderElementKind",
//                alignment: .top
//            )
//        ]
        return section
    }
    
    // MARK: - Types
    
    private enum Section {
        case onDeviceZimFiles
    }
}

@available(iOS 13.0, *)
class ZimFileModernCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let fileNameLabel = UILabel()
    let fileSizeLabel = UILabel()
    let creationDateLabel = UILabel()
    let articleCountLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        contentView.backgroundColor = .tertiarySystemBackground
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        let thumbImageBackgroundView = UIView()
        thumbImageBackgroundView.backgroundColor = .tertiarySystemBackground
        thumbImageBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        fileNameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        fileNameLabel.textColor = .secondaryLabel
        fileNameLabel.numberOfLines = 1
        
        let topTextStack = UIStackView()
        topTextStack.axis = .vertical
        topTextStack.alignment = .leading
        topTextStack.spacing = 4
        topTextStack.addArrangedSubview(titleLabel)
        topTextStack.addArrangedSubview(fileNameLabel)
        
        let topLevelView = UIStackView()
        topLevelView.axis = .horizontal
        topLevelView.alignment = .center
        topLevelView.spacing = UIStackView.spacingUseSystem
        topLevelView.isLayoutMarginsRelativeArrangement = true
        topLevelView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 8, trailing: 10)
        topLevelView.addArrangedSubview(thumbImageBackgroundView)
        topLevelView.addArrangedSubview(topTextStack)
        
        let dividerView = UIView()
        dividerView.backgroundColor = .separator
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        
        [fileSizeLabel, creationDateLabel, articleCountLabel].forEach { label in
            label.font = UIFont.preferredFont(forTextStyle: .footnote)
            label.textColor = .secondaryLabel
            fileNameLabel.numberOfLines = 1
        }
        
        let bottomIndicatorStack = UIStackView()
        
        let bottomTextStack = UIStackView()
        bottomTextStack.axis = .horizontal
        bottomTextStack.alignment = .center
        bottomTextStack.distribution = .equalSpacing
        bottomTextStack.addArrangedSubview(fileSizeLabel)
        bottomTextStack.addArrangedSubview(creationDateLabel)
        bottomTextStack.addArrangedSubview(articleCountLabel)
        
        let bottomLevelView = UIStackView()
        bottomLevelView.axis = .horizontal
        bottomLevelView.alignment = .center
        bottomLevelView.spacing = UIStackView.spacingUseSystem
        bottomLevelView.isLayoutMarginsRelativeArrangement = true
        bottomLevelView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 10, trailing: 10)
        bottomLevelView.addArrangedSubview(bottomIndicatorStack)
        bottomLevelView.addArrangedSubview(bottomTextStack)
        
        let containerView = UIStackView()
        containerView.axis = .vertical
        containerView.alignment = .fill
        containerView.distribution = .fill
        containerView.addArrangedSubview(topLevelView)
        containerView.addArrangedSubview(dividerView)
        containerView.addArrangedSubview(bottomLevelView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            thumbImageBackgroundView.heightAnchor.constraint(equalTo: topTextStack.heightAnchor, multiplier: 0.9),
            thumbImageBackgroundView.heightAnchor.constraint(equalTo: thumbImageBackgroundView.widthAnchor),
            bottomIndicatorStack.widthAnchor.constraint(equalTo: thumbImageBackgroundView.widthAnchor),
        ])
    }
    
    override func draw(_ rect: CGRect) {
        layer.cornerRadius = 16
        layer.masksToBounds = true
    }
}
