//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/16/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit


class MainController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    private var tabConfigs = [TabConfiguration]()
    let tabNavigationController = UIStoryboard(name: "Tab", bundle: nil).instantiateInitialViewController() as! UINavigationController
    private var cellSize = CGSize.zero
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        tabConfigs.append(TabConfiguration())
        collectionView.reloadData()
    }
    
    @IBAction func remove(_ sender: UIBarButtonItem) {
        _ = tabConfigs.popLast()
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculateCellSize(collectionViewSize: collectionView.frame.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        calculateCellSize(collectionViewSize: size)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func calculateCellSize(collectionViewSize size: CGSize) {
        let numberOfItemsPerRow: CGFloat = {
            switch size.width {
            case 0..<400:
                return 1
            case 400..<750:
                return 2
            case 750..<1300:
                return 3
            default:
                return 4
            }
        }()
        let width = ((size.width - (numberOfItemsPerRow + 1) * 10) / numberOfItemsPerRow).rounded(.down)
        let height = traitCollection.horizontalSizeClass == .compact ? 280 : (size.height / size.width * width).rounded(.down)
        cellSize = CGSize(width: width, height: height)
    }
    
    // MARK: -
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabConfigs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if let tabController = tabNavigationController.topViewController as? TabController {
            
        }
        tabNavigationController.transitioningDelegate = self
        present(tabNavigationController, animated: true, completion: nil)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
//        return TabTransitionAnimator(mode: .presenting)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
//        return TabTransitionAnimator(mode: .dismissing)
    }
}

class TabTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration: TimeInterval = 4.0
    let mode: Mode
    
    init(mode: Mode) {
        self.mode = mode
        super.init()
    }
    
    enum Mode {
        case presenting, dismissing
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch mode {
        case .presenting:
            animateForPresenting(context: transitionContext)
        case .dismissing:
            animateForDismissing(context: transitionContext)
        }
        
        
//
//        toView.transform = CGAffineTransform(scaleX: initialFrame.width / finalFrame.width, y: initialFrame.height / finalFrame.height)
//        toView.center = initialCenter
//        toView.alpha = 0.0
//        transitionContext.containerView.addSubview(toView)
//        transitionContext.containerView.bringSubview(toFront: toView)
//
//        UIView.animate(withDuration: duration, animations: {
//            toView.transform = .identity
//            toView.frame = finalFrame
//            toView.alpha = 1.0
//            cell.transform = CGAffineTransform(scaleX: finalFrame.width / initialFrame.width, y: finalFrame.height / initialFrame.height)
//            cell.frame = finalFrame
//            cell.alpha = 0.0
//        }) { _ in
//            transitionContext.completeTransition(true)
//        }
    }
    
    private func animateForPresenting(context: UIViewControllerContextTransitioning) {
//        let containerView = context.containerView
//        guard let fromController = context.viewController(forKey: .from) as? TabsCollectionController,
//            let toView = context.view(forKey: .to),
//            let selected = fromController.collectionView.indexPathsForSelectedItems?.first,
//            let cell = fromController.collectionView.cellForItem(at: selected),
//            let snapshotView = toView.snapshotView(afterScreenUpdates: true) else {
//                context.completeTransition(false)
//                return
//        }
//
//        let cellFrame = containerView.convert(cell.frame, from: fromController.collectionView)
//
//        toView.isHidden = true
//        toView.frame = containerView.bounds
//        containerView.addSubview(toView)
//        containerView.bringSubview(toFront: toView)
//
//        let scale = cellFrame.width / containerView.bounds.width
//        snapshotView.alpha = 0.0
//        snapshotView.frame = containerView.bounds
//        snapshotView.center = cell.center
//        snapshotView.transform = CGAffineTransform(scaleX: scale, y: scale)
//        containerView.addSubview(snapshotView)
//        containerView.bringSubview(toFront: snapshotView)
//
//        UIView.animate(withDuration: duration, animations: {
//            snapshotView.alpha = 1.0
//            snapshotView.transform = .identity
//            snapshotView.center = containerView.center
//        }) { _ in
//            toView.isHidden = false
//            snapshotView.removeFromSuperview()
//            context.completeTransition(true)
//        }
    }
    
    private func animateForDismissing(context: UIViewControllerContextTransitioning) {
//        let containerView = context.containerView
//
//        guard let fromController = context.viewController(forKey: .from) as? UINavigationController,
//            let topController = fromController.topViewController else {
//            context.completeTransition(false)
//            return
//        }
        
//        guard let snapshotView = topController.view.resizableSnapshotView(from: topController.view.bounds, afterScreenUpdates: true, withCapInsets: .zero) else {
//            context.completeTransition(false)
//            return
//        }
//
//
//        guard let fromController = context.viewController(forKey: .from) as? UINavigationController,
//            let toController = context.viewController(forKey: .to) as? MainViewController,
//            let fromView = context.view(forKey: .from),
//            let toView = context.view(forKey: .to) else {
//                context.completeTransition(false)
//                return
//        }
//
//        guard let selected = toController.collectionView.indexPathsForSelectedItems?.first,
//            let cell = toController.collectionView.cellForItem(at: selected) else {
//                context.completeTransition(false)
//                return
//        }
//
//        guard  else {
//            context.completeTransition(false)
//            return
//        }
        
//        snapshotView.frame = fromView.frame
//        containerView.addSubview(snapshotView)
//        containerView.bringSubview(toFront: snapshotView)
//        fromView.removeFromSuperview()
//        toView.frame = containerView.bounds
//        containerView.insertSubview(toView, belowSubview: snapshotView)
//
//        UIView.animate(withDuration: duration, animations: {
//            let scale = containerView.convert(cell.frame, from: toController.collectionView).width / containerView.frame.width
//            snapshotView.transform = CGAffineTransform(scaleX: scale, y: scale)
//            snapshotView.center = containerView.convert(cell.center, from: toController.collectionView)
//        }) { _ in
//            context.completeTransition(true)
//        }
    }
}
