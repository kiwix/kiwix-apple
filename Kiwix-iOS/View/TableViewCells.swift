//
//  BookCell.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

// MARK: - Book Cells (new)

/* Book Cell With P & I indicator */
class BasicBookCell: UITableViewCell {
    
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak private var hasPicIndicator: UILabel!
    @IBOutlet weak private var hasIndexIndicator: UILabel!
    
    // MARK: Override
    
    override func awakeFromNib() {
        hasPicIndicator.layer.cornerRadius = 2.0
        hasIndexIndicator.layer.cornerRadius = 2.0
        hasPicIndicator.layer.masksToBounds = true
        hasIndexIndicator.layer.masksToBounds = true
        hasPicIndicator.backgroundColor = UIColor.clearColor()
        hasIndexIndicator.backgroundColor = UIColor.clearColor()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selected = false
        highlighted = false
    }
    
    // MARK: Shorthand properties
    
    var hasPic: Bool = false {
        didSet {
            hasPicIndicator.layer.backgroundColor = hasPic ? AppColors.hasPicTintColor.CGColor : UIColor.lightGrayColor().CGColor
        }
    }
    
    var hasIndex: Bool = false {
        didSet {
            hasIndexIndicator.layer.backgroundColor = hasIndex ? AppColors.hasIndexTintColor.CGColor : UIColor.lightGrayColor().CGColor
        }
    }
}

/* Book Cell With P & I indicator, a check mark on the right */
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
            accessoryImageView.highlighted = isChecked
        }
    }
    
    func handleTap() {
        self.delegate?.didTapOnAccessoryViewForCell(self)
    }
}

/* Book Cell With progress bar and 2 line detail label */
class DownloadBookCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var detailLabel: UILabel!
    
}

// MARK: - Article Cell

class ArticleCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var hasPicIndicator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
}

class ArticleSnippetCell: ArticleCell {
    @IBOutlet weak var snippetLabel: UILabel!
}

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

// MARK: - Protocol

protocol TableCellDelegate: class {
    func didTapOnAccessoryViewForCell(cell: UITableViewCell)
}

// MARK: - General

class TextSwitchCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
}

class CenterButtonCell: UITableViewCell {
    weak var delegate: CenterButtonCellDelegate?
    @IBOutlet weak var button: UIButton!
    
    @IBAction func buttonTapped(sender: UIButton) {
        delegate?.buttonTapped(self)
    }
}

protocol CenterButtonCellDelegate: class {
    func buttonTapped(cell: CenterButtonCell)
}
