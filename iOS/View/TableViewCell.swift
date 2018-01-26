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
    let snippetLabel = UILabel()
    let thumbImageView = UIImageView()
    let textStackView = UIStackView()
    private var configuredConstraints = false
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
        snippetLabel.text = nil
        thumbImageView.image = nil
    }
    
    override func updateConstraints() {
        defer { super.updateConstraints() }
        guard !configuredConstraints else { return }
        
        NSLayoutConstraint.activate([
            thumbImageView.heightAnchor.constraint(equalToConstant: 34),
            thumbImageView.widthAnchor.constraint(equalToConstant: 34),
            thumbImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbImageView.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            textStackView.leftAnchor.constraint(equalTo: thumbImageView.rightAnchor, constant: 8),
            textStackView.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)])
        
        configuredConstraints = true
    }
    
    func configure() {
        titleLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        snippetLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        snippetLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        snippetLabel.numberOfLines = 0
        snippetLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 4

        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.distribution = .fill
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(snippetLabel)
        
        [thumbImageView, textStackView].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        })
        setNeedsUpdateConstraints()
    }
}
