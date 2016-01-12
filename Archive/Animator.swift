//
//  ShowPageAnimator.swift
//  Kiwix
//
//  Created by Chris on 12/21/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class PresentTabAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    weak var transitionContext: UIViewControllerContextTransitioning?
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.2
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        guard let containerView = transitionContext.containerView()  else {return}
        guard let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? UINavigationController  else {return}
        guard let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? UINavigationController  else {return}
        guard let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)  else {return}
        guard let toView = transitionContext.viewForKey(UITransitionContextToViewKey)  else {return}
        
        guard let collectionView = (fromViewController.topViewController as? UICollectionViewController)?.collectionView else {return}
        guard let indexPath = collectionView.indexPathsForSelectedItems()?.first else {return}
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? TabCVCell else {return}
        
        let cellImageView = UIImageView(image: cell.snapshot)
        let toImageView = UIImageView(image: toView.snapshot)
        
        cellImageView.frame = containerView.convertRect(cell.frame, fromView: collectionView)
        cellImageView.bounds = cellImageView.frame
        toImageView.frame = cellImageView.frame
        toImageView.bounds = toImageView.bounds
        
        containerView.insertSubview(cellImageView, aboveSubview: fromView)
        containerView.insertSubview(toImageView, aboveSubview: cellImageView)
        containerView.insertSubview(toView, aboveSubview: toImageView)
        
        cell.hidden = true
        toImageView.alpha = 0.0
        toView.alpha = 0.0
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
            let toFrame = CGRectMake(0, 20, toView.frame.width, toView.frame.height)
            cellImageView.frame = toFrame
            toImageView.frame = toFrame
            cellImageView.alpha = 0.0
            toImageView.alpha = 1.0
            }) { (completed) -> Void in
                cell.hidden = false
                toView.alpha = 1.0
                cellImageView.removeFromSuperview()
                toImageView.removeFromSuperview()
                transitionContext.completeTransition(true)
        }
    }
}

class DismissTabAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    weak var transitionContext: UIViewControllerContextTransitioning?
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        guard let containerView = transitionContext.containerView() else {return}
        guard let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? UINavigationController else {return}
        guard let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? UINavigationController else {return}
        guard let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey) else {return}
        guard let toView = transitionContext.viewForKey(UITransitionContextToViewKey) else {return}
        
        guard let tabVC = fromViewController.topViewController as? TabVC else {return}
        guard let tabsCVC = toViewController.topViewController as? TabsCVC else {return}
        let collectionView = tabsCVC.collectionView
        
        guard let indexPath = tabsCVC.selectedIndexPath else {return}
        guard let cell = tabsCVC.collectionView?.cellForItemAtIndexPath(indexPath) as? TabCVCell else {return}
        guard let tab = tabsCVC.fetchedResultController.objectAtIndexPath(indexPath) as? Tab else {return}
        if let snapshot = fromView.snapshotViewAfterScreenUpdates(false).snapshot {tab.snapshot = UIImageJPEGRepresentation(snapshot, 1.0)}
        let toFrame = containerView.convertRect(cell.frame, fromView: collectionView)
        
        cell.transform = CGAffineTransformMakeScale(toView.frame.width / cell.frame.width, toView.frame.width / cell.frame.width)
        cell.center = fromView.center
        cell.alpha = 0.0
        
        let fromSnap = fromView.snapshotViewAfterScreenUpdates(false)
        
        
        containerView.insertSubview(fromSnap, belowSubview: fromView)
        containerView.insertSubview(cell, belowSubview: fromSnap)
        containerView.insertSubview(toView, belowSubview: cell)
        fromView.removeFromSuperview()
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
            
            let center = CGPointMake(CGRectGetMidX(toFrame), CGRectGetMidY(toFrame))
            
            fromSnap.center = center
            fromSnap.transform = CGAffineTransformMakeScale(toFrame.width / fromView.frame.width, toFrame.width / fromView.frame.width)
            //fromSnap.alpha = 0.0
            
            cell.center = center
            cell.transform = CGAffineTransformIdentity
            cell.alpha = 1.0
            }) { (completed) -> Void in
                fromSnap.removeFromSuperview()
                cell.removeFromSuperview()
                cell.frame = containerView.convertRect(cell.frame, toView: collectionView)
                collectionView?.addSubview(cell)
                cell.insertSubview(fromSnap, atIndex: 0)
                transitionContext.completeTransition(true)
        }
        
//        let fromImageView = UIImageView(image: fromView.snapshot)
//        let cellImageView = UIImageView(image: cell.snapshot)
//        
//        fromImageView.frame = fromView.frame
//        fromImageView.bounds = fromView.bounds
//        cellImageView.frame = fromView.frame
//        cellImageView.bounds = fromView.bounds
//        
//        containerView.insertSubview(fromImageView, belowSubview: fromView)
//        containerView.insertSubview(cellImageView, belowSubview: fromImageView)
//        containerView.insertSubview(toView, belowSubview: cellImageView)
//        
//        fromView.removeFromSuperview()
//        cellImageView.alpha = 0.0
//        cell.hidden = true
//        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
//            let toFrame = containerView.convertRect(cell.frame, fromView: collectionView)
//            fromImageView.frame = toFrame
//            cellImageView.frame = toFrame
//            fromImageView.alpha = 0.0
//            cellImageView.alpha = 1.0
//            }) { (completed) -> Void in
//                
//                cell.hidden = false
//                fromImageView.removeFromSuperview()
//                cellImageView.removeFromSuperview()
//                transitionContext.completeTransition(true)
//        }
    }
}

extension UIView {
    var snapshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {return nil}
        layer.renderInContext(context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}