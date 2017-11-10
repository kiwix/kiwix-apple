//
//  SearchResultCells.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
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
    
    func configure() {}
}

class SearchResultTitleCell: SearchResultCell {
    let title = UILabel()

    override func configure() {
        title.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        title.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(title)
        NSLayoutConstraint.activate([
            title.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            title.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            title.heightAnchor.constraint(equalToConstant: 24)])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        title.text = nil
    }
}

class SearchResultTitleIconSnippetCell: SearchResultCell {
    let title = UILabel()
    let snippet = UILabel()
    let icon = UIImageView()
    
    override func configure() {
        title.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        snippet.font = UIFont.systemFont(ofSize: 12)
        snippet.numberOfLines = 0
        icon.contentMode = .scaleAspectFit
        [title, snippet, icon].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        })
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            title.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 8),
            title.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            snippet.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 8),
            snippet.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            icon.heightAnchor.constraint(equalToConstant: 30),
            icon.widthAnchor.constraint(equalToConstant: 30),
            icon.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            snippet.topAnchor.constraint(equalTo: title.bottomAnchor),
            snippet.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        title.text = nil
        snippet.text = nil
        icon.image = nil
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
    }
}
