//
//  BookmarkOverlayVC.swift
//  Kiwix
//
//  Created by Chris Li on 1/6/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class BookmarkHUDVC: UIViewController {

    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var starImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        blurView.layer.borderColor = UIColor.blackColor().colorWithAlphaComponent(0.4).CGColor
        blurView.layer.borderWidth = 1.0
        
        blurView.transform = CGAffineTransformMakeScale(0.5, 0.5)
        stackView.transform = CGAffineTransformMakeScale(0.5, 0.5)
    }
    
    func show(text: String?) {
        label.text = text
        UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
            self.blurView.transform = CGAffineTransformIdentity
            self.stackView.transform = CGAffineTransformIdentity
            self.dimView.alpha = 0.6
            }) { (completed) -> Void in
                NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "hide", userInfo: nil, repeats: false)
        }
    }
    
    func hide() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
            self.blurView.transform = CGAffineTransformMakeScale(0.001, 0.001)
            self.stackView.transform = CGAffineTransformMakeScale(0.001, 0.001)
            self.dimView.alpha = 0.0
            }) { (completed) -> Void in
                self.blurView.hidden = true
                self.stackView.hidden = true
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
        }
    }
}

extension LocalizedStrings {
    class var bookmarked: String {return NSLocalizedString("Bookmarked", comment: "")}
    class var removed: String {return NSLocalizedString("Removed", comment: "")}
}