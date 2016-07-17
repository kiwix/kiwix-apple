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
            //let fromController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? BookmarkController,
            //let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey),
            let toView = transitionContext.viewForKey(UITransitionContextToViewKey) else {return}
        let duration = transitionDuration(transitionContext)
        
        containerView.addSubview(toView)
        toView.frame = containerView.frame
        toView.alpha = 0.0
        
        let halfHeight = containerView.frame.height / 2
        toController.centerViewYOffset.constant = -(halfHeight + toController.bottomHalfHeight)
        toController.view.layoutIfNeeded()
        
        UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            toController.centerViewYOffset.constant = 0.0
            toController.view.layoutIfNeeded()
            toView.alpha = 1.0
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
        
        UIView.animateWithDuration(duration * 0.4, delay: 0.0, options: .CurveEaseIn, animations: {
            fromController.centerViewYOffset.constant = halfHeight + fromController.topHalfHeight
            fromController.view.layoutIfNeeded()
            fromView.alpha = 0.6
            }) { (completed) in
                UIView.animateWithDuration(duration * 0.4, delay: 0.0, options: .CurveLinear, animations: {
                    fromView.alpha = 0.0
                    }, completion: { (completed) in
                        transitionContext.completeTransition(completed)
                })
        }
    }
    
    func animationEnded(transitionCompleted: Bool) {
        
    }
}
