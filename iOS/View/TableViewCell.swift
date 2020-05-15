//
//  ArticleTableViewCell.swift
//  iOS
//
//  Created by Chris Li on 1/16/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    let titleLabel = UILabel()
    let detailLabel = UILabel()
    let thumbImageView = UIImageView()
    let thumbImageBackgroundView = UIView()
    fileprivate let textStackView = UIStackView()
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
        titleLabel.text = nil
        detailLabel.text = nil
        thumbImageView.image = nil
    }
    
    override func updateConstraints() {
        defer { super.updateConstraints() }
        guard !configuredConstraints else { return }
        configureConstraints()
        configuredConstraints = true
    }
    
    fileprivate func configure() {
        titleLabel.setContentHuggingPriority(UILayoutPriority(250), for: .vertical)
        detailLabel.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .vertical)
        detailLabel.setContentCompressionResistancePriority(UILayoutPriority(749), for: .vertical)
        detailLabel.numberOfLines = 4
        detailLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 4
        thumbImageBackgroundView.clipsToBounds = true
        thumbImageBackgroundView.layer.cornerRadius = 6
        if #available(iOS 13.0, *) {
            thumbImageBackgroundView.backgroundColor = UIColor(named: "faviconBackground")
        } else {
            thumbImageBackgroundView.backgroundColor = .groupTableViewBackground
        }
        
        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.distribution = .fill
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(detailLabel)
        
        [thumbImageBackgroundView, thumbImageView, textStackView].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        })
        setNeedsUpdateConstraints()
    }
    
    fileprivate func configureConstraints() {
        NSLayoutConstraint.activate([
            thumbImageView.heightAnchor.constraint(equalToConstant: 32),
            thumbImageView.widthAnchor.constraint(equalToConstant: 32),
            thumbImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbImageView.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            thumbImageBackgroundView.heightAnchor.constraint(equalToConstant: 36),
            thumbImageBackgroundView.widthAnchor.constraint(equalToConstant: 36),
            thumbImageBackgroundView.centerXAnchor.constraint(equalTo: thumbImageView.centerXAnchor),
            thumbImageBackgroundView.centerYAnchor.constraint(equalTo: thumbImageView.centerYAnchor),
            textStackView.leftAnchor.constraint(equalTo: thumbImageView.rightAnchor, constant: 8),
            textStackView.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
}

class SearchResultTableViewCell: TableViewCell {
    private let thumbImageCornerRadius: CGFloat = 4
    private let thumbImageBackgroundViewCornerRadius: CGFloat = 6
    
    override fileprivate func configure() {
        super.configure()
        thumbImageView.layer.cornerRadius = 3
        thumbImageBackgroundView.layer.cornerRadius = 3
    }
    
    override fileprivate func configureConstraints() {
        NSLayoutConstraint.activate([
            thumbImageView.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor, constant: -4),
            thumbImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            thumbImageView.widthAnchor.constraint(equalToConstant: 18),
            thumbImageView.heightAnchor.constraint(equalToConstant: 18),
            thumbImageBackgroundView.heightAnchor.constraint(equalToConstant: 20),
            thumbImageBackgroundView.widthAnchor.constraint(equalToConstant: 20),
            thumbImageBackgroundView.centerXAnchor.constraint(equalTo: thumbImageView.centerXAnchor),
            thumbImageBackgroundView.centerYAnchor.constraint(equalTo: thumbImageView.centerYAnchor),
            textStackView.leftAnchor.constraint(equalTo: thumbImageView.rightAnchor, constant: 6),
            textStackView.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }
}

class UIRightDetailTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UIActionTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textLabel?.textAlignment = .center
        textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        textLabel?.textColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isDestructive: Bool = false {
        didSet {
            textLabel?.textColor = isDestructive ? #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
        }
    }
    
    var isDisabled: Bool = false {
        didSet {
            textLabel?.textColor = isDisabled ? #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
        }
    }
    
    override func prepareForReuse() {
        textLabel?.text = nil
        isDestructive = false
        isDisabled = false
    }
}
