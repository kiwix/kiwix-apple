//
//  SearchResultTitleSnippetCell.swift
//  WikiMed
//
//  Created by Chris Li on 9/8/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class SearchResultTitleCell: UITableViewCell {
    let titleLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        configureLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func configureLabel() {
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addConstraints([
            titleLabel.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }
}

class SearchResultTitleSnippetCell: UITableViewCell {
    let titleLabel = UILabel()
    let snippetLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.clear
        configureLabels()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func configureLabels() {
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
        snippetLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        snippetLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addSubview(snippetLabel)
        contentView.addConstraints([
            titleLabel.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: snippetLabel.topAnchor),
            snippetLabel.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            snippetLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            snippetLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            ])
//        contentView.addConstraints([
//            titleLabel.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
//            titleLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
//            snippetLabel.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
//            snippetLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
//            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
//            titleLabel.bottomAnchor.constraint(equalTo: snippetLabel.topAnchor),
//            snippetLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
//        ])
    }
}
