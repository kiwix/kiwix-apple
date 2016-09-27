//
//  BookmarkHUD.swift
//  Kiwix
//
//  Created by Chris Li on 7/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class BookmarkHUD: UIViewController {
    
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
        label.text = bookmarkAdded ? NSLocalizedString("Bookmarked", comment: "Bookmark HUD") : NSLocalizedString("Removed", comment: "Bookmark HUD")
        messageLabel.text = NSLocalizedString("Tap anywhere to dismiss", comment: "Bookmark HUD")
        messageLabel.alpha = 1.0
        imageView.highlighted = !bookmarkAdded
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BookmarkHUD.dismissSelf), userInfo: nil, repeats: false)
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

class BookmarkHUDAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let animateIn: Bool
    
    init(animateIn: Bool) {
        self.animateIn = animateIn
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if animateIn {
            animateInTransition(transitionContext)
        } else {
            animateOutTransition(transitionContext)
        }
    }
    
    private func animateInTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let toController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? BookmarkHUD,
            let toView = transitionContext.viewForKey(UITransitionContextToViewKey) else {return}
        let containerView = transitionContext.containerView()
        let duration = transitionDuration(transitionContext)
        
        containerView.addSubview(toView)
        toView.frame = containerView.frame
        toView.alpha = 0.0
        
        let halfHeight = containerView.frame.height / 2
        toController.centerViewYOffset.constant = toController.bookmarkAdded ? -(halfHeight + toController.bottomHalfHeight) : (halfHeight + toController.topHalfHeight)
        toController.view.layoutIfNeeded()
        
        UIView.animateWithDuration(duration * 0.5, delay: 0.0, options: .CurveLinear, animations: {
            toView.alpha = 1.0
            }, completion: nil)
        
        UIView.animateWithDuration(duration * 0.9, delay: duration * 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            toController.centerViewYOffset.constant = 0.0
            toController.view.layoutIfNeeded()
        }) { (completed) in
            transitionContext.completeTransition(completed)
        }
    }
    
    private func animateOutTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? BookmarkHUD,
            let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey) else {return}
        let containerView = transitionContext.containerView()
        let duration = transitionDuration(transitionContext)
        
        let halfHeight = containerView.frame.height / 2
        fromController.view.layoutIfNeeded()
        
        UIView.animateWithDuration(duration * 0.7, delay: duration * 0.3, options: .CurveLinear, animations: {
            fromView.alpha = 0.0
        }) { (completed) in
            transitionContext.completeTransition(completed)
        }
        
        UIView.animateWithDuration(duration * 0.4, delay: 0.0, options: .CurveEaseIn, animations: {
            fromController.centerViewYOffset.constant = fromController.bookmarkAdded ? halfHeight + fromController.topHalfHeight : -(halfHeight + fromController.bottomHalfHeight)
            fromController.view.layoutIfNeeded()
            }, completion: nil)
        
        if fromController.bookmarkAdded {
            UIView.animateWithDuration(duration * 0.3, delay: 0.0, options: .CurveLinear, animations: {
                fromController.messageLabel.alpha = 0.0
                }, completion: nil)
        }
        
    }
    
    func animationEnded(transitionCompleted: Bool) { }
}
