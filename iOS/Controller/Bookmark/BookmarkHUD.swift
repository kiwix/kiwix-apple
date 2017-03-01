//
//  BookmarkHUD.swift
//  Kiwix
//
//  Created by Chris Li on 7/14/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class BookmarkHUD: UIViewController {
    
    var bookmarkAdded = true
    fileprivate var timer: Timer?
    
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var centerViewYOffset: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomToCenterViewTopSpacing: NSLayoutConstraint!
    @IBOutlet weak var labelToptoCenterViewBottomSpacing: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        label.text = bookmarkAdded ? NSLocalizedString("Bookmarked", comment: "Bookmark HUD") : NSLocalizedString("Removed", comment: "Bookmark HUD")
        messageLabel.text = NSLocalizedString("Tap anywhere to dismiss", comment: "Bookmark HUD")
        messageLabel.alpha = 1.0
        imageView.isHighlighted = !bookmarkAdded
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(BookmarkHUD.dismissSelf), userInfo: nil, repeats: false)
    }
    
    @IBAction func tapRecognized(_ sender: UITapGestureRecognizer) {
        dismissSelf()
    }
    
    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    var topHalfHeight: CGFloat {
        return centerView.frame.height / 2 + imageView.frame.height + imageViewBottomToCenterViewTopSpacing.constant
    }
    
    var bottomHalfHeight: CGFloat {
        return centerView.frame.height / 2 + label.frame.height + labelToptoCenterViewBottomSpacing.constant
    }
}

class BookmarkHUDAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let animateIn: Bool
    
    init(animateIn: Bool) {
        self.animateIn = animateIn
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if animateIn {
            animateInTransition(transitionContext)
        } else {
            animateOutTransition(transitionContext)
        }
    }
    
    private func animateInTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let toController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? BookmarkHUD,
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {return}
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        containerView.addSubview(toView)
        toView.frame = containerView.frame
        toView.alpha = 0.0
        
        let halfHeight = containerView.frame.height / 2
        toController.centerViewYOffset.constant = toController.bookmarkAdded ? -(halfHeight + toController.bottomHalfHeight) : (halfHeight + toController.topHalfHeight)
        toController.view.layoutIfNeeded()
        
        UIView.animate(withDuration: duration * 0.5, delay: 0.0, options: .curveLinear, animations: {
            toView.alpha = 1.0
            }, completion: nil)
        
        UIView.animate(withDuration: duration * 0.9, delay: duration * 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            toController.centerViewYOffset.constant = 0.0
            toController.view.layoutIfNeeded()
        }) { (completed) in
            transitionContext.completeTransition(completed)
        }
    }
    
    private func animateOutTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let fromController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? BookmarkHUD,
            let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else {return}
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        let halfHeight = containerView.frame.height / 2
        fromController.view.layoutIfNeeded()
        
        UIView.animate(withDuration: duration * 0.7, delay: duration * 0.3, options: .curveLinear, animations: {
            fromView.alpha = 0.0
        }) { (completed) in
            transitionContext.completeTransition(completed)
        }
        
        UIView.animate(withDuration: duration * 0.4, delay: 0.0, options: .curveEaseIn, animations: {
            fromController.centerViewYOffset.constant = fromController.bookmarkAdded ? halfHeight + fromController.topHalfHeight : -(halfHeight + fromController.bottomHalfHeight)
            fromController.view.layoutIfNeeded()
            }, completion: nil)
        
        if fromController.bookmarkAdded {
            UIView.animate(withDuration: duration * 0.3, delay: 0.0, options: .curveLinear, animations: {
                fromController.messageLabel.alpha = 0.0
                }, completion: nil)
        }
        
    }
    
    func animationEnded(_ transitionCompleted: Bool) { }
}
