//
//  TabCVCell.swift
//  Kiwix
//
//  Created by Chris on 12/17/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class TabCVCell: UICollectionViewCell {
    
    @IBOutlet weak var visiualEffectView: UIVisualEffectView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var closeButton: LargeHitZoneButton!
    weak var delegate: TabCellDelegate?
    
    override func awakeFromNib() {
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.lightGrayColor().CGColor
        layer.cornerRadius = 5.0
    }
    
    func setImage(image: UIImage?) {
        imageView.image = image
        let width = imageView.bounds.width
        let height = imageView.bounds.height
        imageView.bounds = CGRectMake(0, 0, width, height)
    }
    
    @IBAction func closeButtonTapped(sender: UIButton) {
        delegate?.didTapOnCloseImageForCell(self)
    }
}

protocol TabCellDelegate: class {
    func didTapOnCloseImageForCell(cell: TabCVCell)
}

class LargeHitZoneButton: UIButton {
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let frame = CGRectInset(self.bounds, -9, -9)
        return CGRectContainsPoint(frame, point) ? self : nil
    }
}