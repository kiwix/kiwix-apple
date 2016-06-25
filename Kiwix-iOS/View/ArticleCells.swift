//
//  SearchResultCell.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class ArticleCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var hasPicIndicator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
}

class ArticleSnippetCell: ArticleCell {
    @IBOutlet weak var snippetLabel: UILabel!
}