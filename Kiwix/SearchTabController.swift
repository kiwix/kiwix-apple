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
    
    private let indicatorView = UIView()
    private let controllers = [UIStoryboard.main.initViewController(SearchLocalBooksCVC.self)!,
        UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Controller1"),
        UIStoryboard.main.initViewController(SearchScopeSelectTBVC.self)!]
    private let appColor = UIColor(red: 71.0 / 255.0, green: 128.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0)
    
    private var currentHighlightedButtonIndex: Int = 0
    private var buttons = [UIButton]()
    @IBOutlet weak var mainPageButton: UIButton!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast

        tabsContainer.addSubview(indicatorView)
        indicatorView.backgroundColor = appColor
        
        tabsContainer.layer.masksToBounds = false
        tabsContainer.layer.shadowOffset = CGSizeMake(0, 0)
        tabsContainer.layer.shadowOpacity = 0.5
        tabsContainer.layer.shadowRadius = 2.0
        
        buttons = [mainPageButton, historyButton, settingButton]
        mainPageButton.setImage(UIImage(named: "MainPage")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        mainPageButton.setImage(UIImage(named: "MainPage_filled")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Highlighted)
        mainPageButton.tintColor = UIColor.grayColor()
        historyButton.setImage(UIImage(named: "History")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        historyButton.setImage(UIImage(named: "History_filled")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Highlighted)
        historyButton.tintColor = UIColor.grayColor()
        buttons[currentHighlightedButtonIndex].highlighted = true
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
        setButtonHighlightingStatus()
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
    
    func setButtonHighlightingStatus() {
        let indexOfButtonShouldBeHighlighted: Int = {
            let currentPosition = currentControllerPosition
            let index = currentPosition.index
            let percentage = currentPosition.percentage
            return percentage > 0.5 ? index + 1 : index
        }()
        guard indexOfButtonShouldBeHighlighted != currentHighlightedButtonIndex else {return}
        buttons[currentHighlightedButtonIndex].highlighted = false
        buttons[currentHighlightedButtonIndex].tintColor = UIColor.grayColor()
        buttons[indexOfButtonShouldBeHighlighted].highlighted = true
        buttons[indexOfButtonShouldBeHighlighted].tintColor = appColor
        currentHighlightedButtonIndex = indexOfButtonShouldBeHighlighted
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
