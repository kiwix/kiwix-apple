//
//  ArticleTableCells.swift
//  iOS
//
//  Created by Chris Li on 1/16/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class ArticleTableCell: UITableViewCell {
    let titleLabel = UILabel()
    let snippetLabel = UILabel()
    let faviconImageView = UIImageView()
    private let textStackView = UIStackView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        configure()
    }
    
    func configure() {
        titleLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        snippetLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        snippetLabel.numberOfLines = 0
        snippetLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        faviconImageView.contentMode = .scaleAspectFit

        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.distribution = .fill
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(snippetLabel)
        
        [faviconImageView, textStackView].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        })
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            faviconImageView.heightAnchor.constraint(equalToConstant: 30),
            faviconImageView.widthAnchor.constraint(equalToConstant: 30),
            faviconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            faviconImageView.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            textStackView.leftAnchor.constraint(equalTo: faviconImageView.rightAnchor, constant: 8),
            textStackView.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)])
    }
}
