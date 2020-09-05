//
//  HomeController.swift
//  Kiwix
//
//  Created by Chris Li on 8/30/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class HomeController: UICollectionViewController {
    
    let items = [
        [
            "1 Lorem ipsum dolor sit amet.",
            "2 Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            "3 Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            "4 Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            "5 Lorem ipsum dolor sit amet.",
        ],
        [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.",
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        ],
        [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.",
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            "Lorem ipsum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout { (index, environment) -> NSCollectionLayoutSection? in
            if environment.traitCollection.horizontalSizeClass == .compact {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(50))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item, item, item])
                group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = -26
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 36)
                section.orthogonalScrollingBehavior = .groupPaging
                section.boundarySupplementaryItems = [
                    NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)
                        ),
                        elementKind: "SectionHeaderElementKind",
                        alignment: .top
                    )
                ]
                return section
            } else {
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
                section.boundarySupplementaryItems = [
                    NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)
                        ),
                        elementKind: "SectionHeaderElementKind",
                        alignment: .top
                    )
                ]
                return section
            }
        }
        collectionView.register(CustomCell.self, forCellWithReuseIdentifier: "CustomCell")
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell
        cell.titleLabel.text = items[indexPath.section][indexPath.row]
        cell.fileNameLabel.text = "placeholder_file_name.zim"
        cell.fileSizeLabel.text = "95.3GB"
        cell.creationDateLabel.text = "Aug 15, 2020"
        cell.articleCountLabel.text = "35.5K articles"
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView", for: indexPath) as! HeaderView
        headerView.label.text = "Header"
        return headerView
    }
}

@available(iOS 13.0, *)
class HeaderView: UICollectionReusableView {

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

@available(iOS 13.0, *)
class CustomCell: UICollectionViewCell {
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

private extension UIFont {
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        return metrics.scaledFont(for: font)
    }
}
