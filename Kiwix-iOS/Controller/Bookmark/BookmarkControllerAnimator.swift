//
//  BookmarkControllerAnimator.swift
//  Kiwix
//
//  Created by Chris Li on 7/15/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class BookmarkControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
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
        guard let containerView = transitionContext.containerView(),
            let toController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? BookmarkController,
            let toView = transitionContext.viewForKey(UITransitionContextToViewKey) else {return}
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
        guard let containerView = transitionContext.containerView(),
            let fromController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? BookmarkController,
            let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey) else {return}
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
    
    func animationEnded(transitionCompleted: Bool) {
        
    }
}
