//
//  RecentSearchCells.swift
//  iOS
//
//  Created by Chris Li on 1/31/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class RecentSearchTableViewCell: UITableViewCell {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var configuredConstraints = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }
    
    override func updateConstraints() {
        defer { super.updateConstraints() }
        guard !configuredConstraints else { return }
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            contentView.leftAnchor.constraint(equalTo: collectionView.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: collectionView.rightAnchor)])
        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        
        configuredConstraints = true
    }
    
    private func configure() {
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(RecentSearchCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        setNeedsUpdateConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: layoutMargins.left, bottom: 0, right: layoutMargins.right)
    }
}

class RecentSearchCollectionViewCell: UICollectionViewCell {
    let label = UILabel()
    private var configuredConstraints = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override func draw(_ rect: CGRect) {
        layer.cornerRadius = rect.height / 2
    }
    
    override func updateConstraints() {
        defer { super.updateConstraints() }
        guard !configuredConstraints else { return }
        
        NSLayoutConstraint.activate([
            contentView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: label.centerXAnchor)])
        
        configuredConstraints = true
    }
    
    private func configure() {
        if #available(iOS 13.0, *) {
            label.textColor = .label
            backgroundColor = .systemGroupedBackground
        } else {
            label.textColor = .darkText
            backgroundColor = #colorLiteral(red: 0.9117823243, green: 0.9118037224, blue: 0.9117922187, alpha: 1)
        }
        
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        clipsToBounds = true
        contentView.addSubview(label)
        setNeedsUpdateConstraints()
    }
}
