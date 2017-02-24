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

// MARK: - Search

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

protocol TableCellDelegate: class {
    func didTapCheckMark(cell: UITableViewCell)
}

class ArticleCell: FavIconAndPicIndicatorCell {
    @IBOutlet weak var titleLabel: UILabel!
}

class ArticleSnippetCell: ArticleCell {
    @IBOutlet weak var snippetLabel: UILabel!
}

class RecentSearchCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        layer.cornerRadius = 15.0
        layer.masksToBounds = true
        backgroundColor = AppColors.theme
    }
}


// MARK: - Bookmark

class BookmarkCollectionCell: UICollectionViewCell {
    override func awakeFromNib() {
        clipsToBounds = false
        backgroundColor = UIColor.clear
        layer.masksToBounds = false
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 1.0
        
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor.white
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 2.0
        
        thumbImageView.layer.cornerRadius = 4.0
        thumbImageView.clipsToBounds = true
        
        dividerView.layer.cornerRadius = 1
        dividerView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 2.0).cgPath
    }
    
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookmarkDetailLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? UIColor(colorLiteralRed: 200/255, green: 220/255, blue: 1, alpha: 1) : UIColor.white
        }
    }
}

// MARK: - Library Cell

class LibraryCollectionCell: UICollectionViewCell {
    override func awakeFromNib() {
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 2.0
        hasPicLabel.layer.borderWidth = 1.5
        hasPicLabel.layer.borderColor = UIColor.orange.cgColor
        hasPicLabel.layer.cornerRadius = 8.0
    }
    
    @IBAction func moreButtonTapped(_ sender: UIButton) {
        delegate?.didTapMoreButton(cell: self)
    }
    
    var spaceStatus: SpaceStatus? {
        didSet {
            guard let spaceStatus = spaceStatus else {return}
            switch spaceStatus {
            case .enough:
                titleLabel.textColor = UIColor.black
                subtitleLabel.textColor = UIColor.black
                descriptionLabel.textColor = UIColor.black
                hasPicLabel.textColor = UIColor.orange
                hasPicLabel.layer.borderColor = UIColor.orange.cgColor
            case .caution:
                titleLabel.textColor = UIColor.orange
                subtitleLabel.textColor = UIColor.orange
                descriptionLabel.textColor = UIColor.orange
                hasPicLabel.textColor = UIColor.orange
                hasPicLabel.layer.borderColor = UIColor.orange.cgColor
            case .notEnough:
                titleLabel.textColor = UIColor.gray
                subtitleLabel.textColor = UIColor.gray
                descriptionLabel.textColor = UIColor.gray
                hasPicLabel.textColor = UIColor.gray
                hasPicLabel.layer.borderColor = UIColor.gray.cgColor
            }
        }
    }
    
    weak var delegate: LibraryCollectionCellDelegate?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var hasPicLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? UIColor(colorLiteralRed: 200/255, green: 220/255, blue: 1, alpha: 1) : UIColor.clear
        }
    }
}


enum SpaceStatus {
    case enough, caution, notEnough
}

protocol LibraryCollectionCellDelegate: class {
    func didTapMoreButton(cell: LibraryCollectionCell)
}

class LibraryCollectionHeader: UICollectionReusableView {
    @IBOutlet weak var textLabel: UILabel!
}

class DownloadTaskCell: UITableViewCell {
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
}







// MARK: - legacy

class BasicBookCell: FavIconAndPicIndicatorCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}
