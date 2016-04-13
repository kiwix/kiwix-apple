//
//  BookCell.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

// MARK: - Normal Cells

class ScopeBookCell: UITableViewCell {
    private let hasPicIndicatorOrange = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    private let hasIndexIndicatorBlue = UIColor(red: 0.304706, green: 0.47158, blue: 1, alpha: 1)
    
    override func awakeFromNib() {
        hasPicIndicator.layer.cornerRadius = 2.0
        hasIndexIndicator.layer.cornerRadius = 2.0
        hasPicIndicator.layer.masksToBounds = true
        hasIndexIndicator.layer.masksToBounds = true
    }
    
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var hasPicIndicator: UILabel!
    @IBOutlet weak var hasIndexIndicator: UILabel!
    
    var hasPic: Bool = false {
        didSet {
            hasPicIndicator.backgroundColor = hasPic ? hasPicIndicatorOrange : UIColor.lightGrayColor()
        }
    }
    
    var hasIndex: Bool = false {
        didSet {
            hasIndexIndicator.backgroundColor = hasIndex ? hasIndexIndicatorBlue : UIColor.lightGrayColor()
        }
    }
    
    override func prepareForReuse() {
        hasPic = false
        hasIndex = false
    }
}

class LocalBookCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var hasPicIndicator: UIView!
}

// MARK:- Book Table Cells

class CloudBookCell: BookTableCell {
    
}

class DownloadBookCell: BookTableCell {
    @IBOutlet weak var articleCountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        articleCountLabel.text = nil
        dateLabel.text = nil
        progressView.progress = 0.0
    }
}

class BookTableCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var hasPicIndicator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var accessoryImageView: LargeHitZoneImageView!
    weak var delegate: BookTableCellDelegate?
    
    var accessoryImageTintColor: UIColor? {
        didSet {
            guard let imageRenderingMode = accessoryImageView.image?.renderingMode else {return}
            if imageRenderingMode != .AlwaysTemplate {
                accessoryImageView.image = accessoryImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
            }
            accessoryImageView.tintColor = accessoryImageTintColor
        }
    }
    
    var accessoryHighlightedImageTintColor: UIColor? {
        didSet {
            guard let imageRenderingMode = accessoryImageView.highlightedImage?.renderingMode else {return}
            if imageRenderingMode != .AlwaysTemplate {
                accessoryImageView.highlightedImage = accessoryImageView.highlightedImage?.imageWithRenderingMode(.AlwaysTemplate)
            }
            accessoryImageView.tintColor = accessoryHighlightedImageTintColor
        }
    }
    
    override func awakeFromNib() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap")
        accessoryImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func handleTap() {
        self.delegate?.didTapOnAccessoryViewForCell(self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        favIcon.image = nil
        hasPicIndicator.backgroundColor = UIColor.lightGrayColor()
        titleLabel.text = nil
        subtitleLabel.text = nil
        accessoryImageView.highlighted = false
    }
}

// MARK: - Protocol

protocol BookTableCellDelegate: class {
    func didTapOnAccessoryViewForCell(cell: BookTableCell)
}