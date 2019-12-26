//
//  MessageController.swift
//  iOS
//
//  Created by Chris Li on 1/15/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class HUDController: UIViewController, UIViewControllerTransitioningDelegate {
    private let visualView = UIVisualEffectView(effect: {
        if #available(iOS 13.0, *) {
            return UIBlurEffect(style: .systemMaterial)
        } else {
            return UIBlurEffect(style: .extraLight)
        }
    }())
    private let stackView = UIStackView()
    let imageView = UIImageView()
    let label = UILabel()
    var direction: HUDAnimationDirection = .down
    
    override func loadView() {
        view = visualView
        visualView.layer.cornerRadius = 10
        visualView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = { if #available(iOS 13.0, *) { return .secondaryLabel } else { return .gray } }()
        
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
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HUDAnimator(direction: direction, isPresentation: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HUDAnimator(direction: direction, isPresentation: false)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HUDPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
class HUDAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let direction: HUDAnimationDirection
    let isPresentation: Bool
    
    init(direction: HUDAnimationDirection, isPresentation: Bool) {
        self.direction = direction
        self.isPresentation = isPresentation
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedView = transitionContext.view(forKey: isPresentation ? .to : .from),
            let presentedController = transitionContext.viewController(forKey: isPresentation ? .to : .from) else {return}
        let containerView = transitionContext.containerView

        var initialFrame = transitionContext.initialFrame(for: presentedController)
        var finalFrame = transitionContext.finalFrame(for: presentedController)
        
        if isPresentation {
            let dy = direction == .up ? containerView.frame.height - finalFrame.minY : -finalFrame.maxY
            initialFrame = finalFrame.offsetBy(dx: 0, dy: dy)
        } else {
            let dy = direction == .up ? -initialFrame.maxY : containerView.frame.height - initialFrame.minY
            finalFrame = initialFrame.offsetBy(dx: 0, dy: dy)
        }
        
        if isPresentation {
            transitionContext.containerView.addSubview(presentedView)
        }
        presentedView.frame = initialFrame
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0.0,
                       usingSpringWithDamping: isPresentation ? 0.7 : 1.0,
                       initialSpringVelocity: 0.0,
                       options: isPresentation ? .curveEaseOut : .curveEaseIn,
                       animations:{ presentedView.frame = finalFrame
        }) { (finished) in
            transitionContext.completeTransition(finished)
        }
    }
}

class HUDPresentationController: UIPresentationController {
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        let dimension = min(250, parentSize.height * 0.5, parentSize.width * 0.5)
        return CGSize(width: dimension, height: dimension)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {return .zero}
        var frame = CGRect.zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
        return frame.offsetBy(dx: (containerView.bounds.width - frame.width) / 2, dy: (containerView.bounds.height - frame.height) / 2)
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}

enum HUDAnimationDirection {
    case up, down
}
