//
//  SidePanelController.swift
//  iOS
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SidePanelController: UIViewController, UIViewControllerTransitioningDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
    }
    func setContent(controller: UIViewController?) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        
        guard let controller = controller else {return}
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controller.view.rightAnchor.constraint(equalTo: view.rightAnchor)])
        controller.didMove(toParentViewController: self)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SidePanelControllerAnimator(isPresentation: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SidePanelControllerAnimator(isPresentation: false)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SidePanelPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class SidePanelControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresentation: Bool
    
    init(isPresentation: Bool) {
        self.isPresentation = isPresentation
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedView = transitionContext.view(forKey: isPresentation ? .to : .from),
            let presentedController = transitionContext.viewController(forKey: isPresentation ? .to : .from) else {return}
        
        var initialFrame = transitionContext.initialFrame(for: presentedController)
        var finalFrame = transitionContext.finalFrame(for: presentedController)
        
        if isPresentation {
            initialFrame = finalFrame.offsetBy(dx: -finalFrame.width, dy: 0)
        } else {
            finalFrame = initialFrame.offsetBy(dx: -initialFrame.width, dy: 0)
        }
        
        if isPresentation {
            transitionContext.containerView.addSubview(presentedView)
        }
        presentedView.frame = initialFrame
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            presentedView.frame = finalFrame
        }) { (completed) in
            transitionContext.completeTransition(completed)
        }
    }
}


class SidePanelPresentationController: UIPresentationController, UIAdaptivePresentationControllerDelegate {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {return .zero}
        let size = self.size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
        return CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width * 0.3, height: parentSize.height)
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func presentationTransitionWillBegin() {
        
    }
}
