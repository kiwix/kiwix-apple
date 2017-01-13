//
//  BookCell.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

// MARK: - Base Class

class FavIconAndPicIndicatorCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var hasPicIndicator: UIView!
    
    override func awakeFromNib() {
        hasPicIndicator.layer.cornerRadius = 1.0
        hasPicIndicator.layer.masksToBounds = true
        hasPicIndicator.backgroundColor = UIColor.clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
        isHighlighted = false
    }
    
    // MARK: Override
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setIndicatorColor()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setIndicatorColor()
    }
    
    // MARK: Shorthand properties
    
    var hasPic: Bool = false {
        didSet {
            setIndicatorColor()
        }
    }
    
    private func setIndicatorColor() {
        hasPicIndicator.backgroundColor = hasPic ? AppColors.hasPicTintColor : UIColor.lightGray
    }
}

// MARK: - BasicBookCell

class BasicBookCell: FavIconAndPicIndicatorCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}

// MARK: - DownloadBookCell

class DownloadBookCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
}

// MARK: - CheckMarkBookCell

class CheckMarkBookCell: BasicBookCell {
    @IBOutlet weak var accessoryImageView: LargeHitZoneImageView!
    weak var delegate: TableCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CheckMarkBookCell.handleTap))
        accessoryImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    var isChecked: Bool = false {
        didSet {
            accessoryImageView.isHighlighted = isChecked
        }
    }
    
    func handleTap() {
        self.delegate?.didTapCheckMark(cell: self)
    }
}

// MARK: - Article Cell

class BookmarkCollectionCell: UICollectionViewCell {
    override func awakeFromNib() {
        thumbImageView.layer.cornerRadius = 4.0
        thumbImageView.clipsToBounds = true
    }
    
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
}

class ArticleCell: FavIconAndPicIndicatorCell {
    @IBOutlet weak var titleLabel: UILabel!
}

class ArticleSnippetCell: ArticleCell {
    @IBOutlet weak var snippetLabel: UILabel!
}



// MARK: - last time refactor

// MARK: - Bookmark Cell

class BookmarkCell: UITableViewCell {
    override func awakeFromNib() {
        thumbImageView.layer.cornerRadius = 4.0
        thumbImageView.clipsToBounds = true
    }
    
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}

class BookmarkSnippetCell: BookmarkCell {
    @IBOutlet weak var snippetLabel: UILabel!
}

// MARK: - Recent Search Cell

class LocalLangCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        layer.cornerRadius = 15.0
        layer.masksToBounds = true
        backgroundColor = UIColor.themeColor
    }
}

// MARK: - Other

class TextSwitchCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
}

protocol TableCellDelegate: class {
    func didTapCheckMark(cell: UITableViewCell)
}
