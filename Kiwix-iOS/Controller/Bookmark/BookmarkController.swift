//
//  BookmarkController.swift
//  Kiwix
//
//  Created by Chris Li on 7/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class BookmarkController: UIViewController {
    
    var bookmarkAdded = true
    private var timer: NSTimer?
    
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var centerViewYOffset: NSLayoutConstraint!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        label.text = bookmarkAdded ? NSLocalizedString("Bookmarked", comment: "Bookmark Overlay") : NSLocalizedString("Removed", comment: "Bookmark Overlay")
        messageLabel.text = NSLocalizedString("Tap anywhere to dismiss", comment: "Bookmark Overlay")
        imageView.highlighted = !bookmarkAdded
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BookmarkController.dismissSelf), userInfo: nil, repeats: false)
    }
    
    @IBAction func tapRecognized(sender: UITapGestureRecognizer) {
        dismissSelf()
    }
    
    func dismissSelf() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    var topHalfHeight: CGFloat {
        return centerView.frame.height / 2 + imageView.frame.height
    }
    
    var bottomHalfHeight: CGFloat {
        return centerView.frame.height / 2 + label.frame.height
    }
}