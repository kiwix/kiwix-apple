//
//  LibraryTableCells.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit


class LibraryDownloadCell: UITableViewCell {
    let logoView = UIImageView()
    let titleLabel = UILabel()
    let stateLabel = UILabel()
    let progressLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configConstraints()
    }
    
    private func configConstraints() {
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.contentMode = .scaleAspectFit
        contentView.addSubview(logoView)
        contentView.addConstraints([
            logoView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            logoView.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            logoView.heightAnchor.constraint(equalToConstant: 30),
            logoView.widthAnchor.constraint(equalToConstant: 30)])
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addConstraints([
            titleLabel.heightAnchor.constraint(equalToConstant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 2),
            titleLabel.leftAnchor.constraint(equalTo: logoView.rightAnchor, constant: 8),
            titleLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor)])
        stateLabel.font = UIFont.systemFont(ofSize: 12)
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stateLabel)
        contentView.addConstraints([
            stateLabel.heightAnchor.constraint(equalToConstant: 16),
            stateLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 2),
            stateLabel.leftAnchor.constraint(equalTo: logoView.rightAnchor, constant: 8)])
        progressLabel.font = UIFont.systemFont(ofSize: 12)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progressLabel)
        contentView.addConstraints([
            progressLabel.heightAnchor.constraint(equalToConstant: 16),
            progressLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 2),
            progressLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor)])
        
        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
}
