//
//  SearchTabController.swift
//  PageViewController
//
//  Created by Chris Li on 3/31/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class SearchTabController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var tabsContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let indicatorView = UIView()
    let swipeGestureRecognizer = UISwipeGestureRecognizer()
    let controllers = [UIStoryboard.main.initViewController(SearchLocalBooksCVC.self)!,
        UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Controller1"),
        UIStoryboard.main.initViewController(SearchScopeSelectTBVC.self)!]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast

        tabsContainer.addSubview(indicatorView)
        indicatorView.backgroundColor = UIColor(red: 71.0 / 255.0, green: 128.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0)
        
        tabsContainer.layer.masksToBounds = false
        tabsContainer.layer.shadowOffset = CGSizeMake(0, 0)
        tabsContainer.layer.shadowOpacity = 0.5
        tabsContainer.layer.shadowRadius = 2.0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = scrollView.frame.width
        let height = scrollView.frame.height
        var x: CGFloat = 0
        for controller in controllers {
            addChildViewController(controller)
            controller.view.frame = CGRectMake(x, 0, width, height)
            scrollView.addSubview(controller.view)
            controller.didMoveToParentViewController(self)
            x += width
        }
        scrollView.contentSize = CGSizeMake(x, height)
        setIndicatorViewFrame()
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        setIndicatorViewFrame()
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollViewAnimateIntoPosition()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else {return}
        scrollViewAnimateIntoPosition()
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        let currentPosition = currentControllerPosition
        let index = currentPosition.index
        let xVelocity = scrollView.panGestureRecognizer.velocityInView(scrollView).x
        scrollToControllerAtIndex(xVelocity > 0 ? index : index + 1)
    }
    
    // MARK: -
    
    var currentControllerPosition: (index: Int, percentage: Double) {
        let multiplier = scrollView.contentOffset.x / scrollView.frame.width
        let index = Int(multiplier)
        let percentage = Double(multiplier) - Double(index)
        return (index, percentage)
    }
    
    func setIndicatorViewFrame() {
        let percentage = scrollView.contentOffset.x / scrollView.contentSize.width
        let height: CGFloat = 2
        let width = tabsContainer.frame.width / 3
        let x = tabsContainer.frame.width * percentage
        let y = tabsContainer.frame.height - height
        indicatorView.frame = CGRectMake(x, y, width, height)
    }
    
    func scrollViewAnimateIntoPosition() {
        let currentPosition = currentControllerPosition
        let index = currentPosition.index
        let percentage = currentPosition.percentage
        scrollToControllerAtIndex(percentage > 0.5 ? index + 1 : index)
    }
    
    func scrollToControllerAtIndex(index: Int) {
        guard index >= 0 && index < controllers.count else {return}
        let frame = controllers[index].view.frame
        scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction func mainPageButtonTapped(sender: UIButton) {
        scrollToControllerAtIndex(0)
    }
    
    @IBAction func historyButtonTapped(sender: UIButton) {
        scrollToControllerAtIndex(1)
    }
    
    @IBAction func scopeButtonTapped(sender: UIButton) {
        scrollToControllerAtIndex(2)
    }
    
}
