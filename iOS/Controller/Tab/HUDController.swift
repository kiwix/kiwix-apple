//
//  MessageController.swift
//  iOS
//
//  Created by Chris Li on 1/15/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class HUDController: UIViewController, UIViewControllerTransitioningDelegate {
    let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    var direction: HUDAnimationDirection = .down
    
    override func loadView() {
        view = visualView
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HUDTransitionAnimator(direction: direction, presenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HUDTransitionAnimator(direction: direction, presenting: false)
    }
}

class HUDTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let direction: HUDAnimationDirection
    let presenting: Bool
    
    init(direction: HUDAnimationDirection, presenting: Bool) {
        self.direction = direction
        self.presenting = presenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        guard let hud = transitionContext.view(forKey: presenting ? .to : .from) else {
            transitionContext.completeTransition(false)
            return
        }
        
        hud.layer.cornerRadius = 10
        hud.clipsToBounds = true
        
        container.isUserInteractionEnabled = false
        hud.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hud)

        NSLayoutConstraint.activate([
            hud.heightAnchor.constraint(equalToConstant: 250),
            hud.widthAnchor.constraint(equalToConstant: 250),
            hud.centerXAnchor.constraint(equalTo: container.centerXAnchor)])
        
        let topConstraint = hud.bottomAnchor.constraint(equalTo: container.topAnchor)
        let centerConstraint = hud.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        let bottomConstraint = hud.topAnchor.constraint(equalTo: container.bottomAnchor)
        
        topConstraint.priority = .defaultLow
        centerConstraint.priority = .defaultLow
        bottomConstraint.priority = .defaultLow
        
        switch (presenting, direction) {
        case (false, _):
            centerConstraint.priority = .defaultHigh
        case (true, .up):
            bottomConstraint.priority = .defaultHigh
        case (true, .down):
            topConstraint.priority = .defaultHigh
        }
        
        topConstraint.isActive = true
        centerConstraint.isActive = true
        bottomConstraint.isActive = true

        container.layoutIfNeeded()

        topConstraint.priority = .defaultLow
        centerConstraint.priority = .defaultLow
        bottomConstraint.priority = .defaultLow

        switch (presenting, direction) {
        case (true, _):
            centerConstraint.priority = .defaultHigh
        case (false, .up):
            topConstraint.priority = .defaultHigh
        case (false, .down):
            bottomConstraint.priority = .defaultHigh
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0.0,
                       usingSpringWithDamping: presenting ? 0.7 : 1.0,
                       initialSpringVelocity: 0.0,
                       options: presenting ? .curveEaseOut : .curveEaseIn,
                       animations:{ container.layoutIfNeeded()
        }) { (finished) in
            NSLayoutConstraint.deactivate(container.constraints)
            NSLayoutConstraint.deactivate(hud.constraints)
            transitionContext.completeTransition(true)
        }
    }
}

enum HUDAnimationDirection {
    case up, down
}
