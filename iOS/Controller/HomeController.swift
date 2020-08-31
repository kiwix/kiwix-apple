//
//  HomeController.swift
//  iOS
//
//  Created by Chris Li on 8/30/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 14.0, *)
class HomeController: UICollectionViewController {
    
    let items = [
        [
            "Lorem ipsum dolor sit amet.",
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
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

        let size = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(44)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        section.interGroupSpacing = 10

        let headerFooterSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40)
        )
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: "SectionHeaderElementKind",
            alignment: .top
        )
        section.boundarySupplementaryItems = [sectionHeader]

        let layout = UICollectionViewCompositionalLayout(section: section)
        collectionView.collectionViewLayout = layout
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

}

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

@available(iOS 14.0, *)
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
        NSLayoutConstraint.activate([
            thumbImageBackgroundView.heightAnchor.constraint(equalTo: topTextStack.heightAnchor, multiplier: 0.9),
            thumbImageBackgroundView.heightAnchor.constraint(equalTo: thumbImageBackgroundView.widthAnchor)
        ])
        
        let dividerView = UIView()
        dividerView.backgroundColor = .separator
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        
        [fileSizeLabel, creationDateLabel, articleCountLabel].forEach { label in
            label.font = UIFont.preferredFont(forTextStyle: .footnote)
            label.textColor = .secondaryLabel
            fileNameLabel.numberOfLines = 1
        }
        
        let bottomLevelView = UIStackView()
        bottomLevelView.axis = .horizontal
        bottomLevelView.alignment = .center
        bottomLevelView.distribution = .equalSpacing
        bottomLevelView.isLayoutMarginsRelativeArrangement = true
        bottomLevelView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 10, trailing: 10)
        bottomLevelView.addArrangedSubview(fileSizeLabel)
        bottomLevelView.addArrangedSubview(creationDateLabel)
        bottomLevelView.addArrangedSubview(articleCountLabel)
        
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
