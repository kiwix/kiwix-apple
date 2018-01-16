//
//  MessageController.swift
//  iOS
//
//  Created by Chris Li on 1/15/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class HUDController: UIViewController, UIViewControllerTransitioningDelegate {
    private let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    let stackView = UIStackView()
    
    let imageView = UIImageView(image: #imageLiteral(resourceName: "StarAdd"))
    let label = UILabel()
    var direction: HUDAnimationDirection = .down
    
    override func loadView() {
        view = visualView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        visualView.contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: visualView.contentView.widthAnchor, multiplier: 0.8),
            stackView.heightAnchor.constraint(equalTo: visualView.contentView.heightAnchor, multiplier: 0.8),
            stackView.centerXAnchor.constraint(equalTo: visualView.contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: visualView.contentView.centerYAnchor)])
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
        NSLayoutConstraint.deactivate(container.constraints)
        NSLayoutConstraint.deactivate(hud.constraints)
        
        hud.layer.cornerRadius = 10
        hud.clipsToBounds = true
        
        container.isUserInteractionEnabled = false
        hud.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hud)

        NSLayoutConstraint.activate([
            hud.heightAnchor.constraint(lessThanOrEqualTo: container.heightAnchor, multiplier: 0.5),
            hud.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, multiplier: 0.5),
            hud.widthAnchor.constraint(equalTo: hud.heightAnchor),
            hud.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
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
            transitionContext.completeTransition(true)
        }
    }
}

enum HUDAnimationDirection {
    case up, down
}
