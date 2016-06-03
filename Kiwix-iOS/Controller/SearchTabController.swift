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
        UIStoryboard.main.initViewController(SearchHistoryTBVC.self)!,
        UIStoryboard.main.initViewController(SearchScopeSelectTBVC.self)!]
    
    private var currentSelectedButtonIndex: Int = 0
    private var buttons = [UIButton]()
    @IBOutlet weak var mainPageButton: UIButton!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    var shouldClipRoundCorner: Bool {
        return traitCollection.verticalSizeClass == .Regular && traitCollection.horizontalSizeClass == .Regular
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast

        tabsContainer.addSubview(indicatorView)
        indicatorView.backgroundColor = UIColor.themeColor
        
        tabsContainer.layer.masksToBounds = false
        tabsContainer.layer.shadowOffset = CGSizeMake(0, 0)
        tabsContainer.layer.shadowOpacity = 0.5
        tabsContainer.layer.shadowRadius = 2.0
        
        buttons = [mainPageButton, historyButton, settingButton]
        mainPageButton.setImage(UIImage(named: "MainPage")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        mainPageButton.setImage(UIImage(named: "MainPage_filled")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
        mainPageButton.tintColor = UIColor.grayColor()
        historyButton.setImage(UIImage(named: "History")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        historyButton.setImage(UIImage(named: "History_filled")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
        historyButton.tintColor = UIColor.grayColor()
        settingButton.setImage(UIImage(named: "SearchSetting")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        settingButton.setImage(UIImage(named: "SearchSetting_filled")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
        settingButton.tintColor = UIColor.grayColor()
        buttons[currentSelectedButtonIndex].selected = true
        buttons[currentSelectedButtonIndex].tintColor = UIColor.themeColor
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
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        view.layer.cornerRadius = shouldClipRoundCorner ? 10.0 : 0.0
        view.layer.masksToBounds = shouldClipRoundCorner
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        setIndicatorViewFrame()
        setButtonSelectedStatus()
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
    
    func setButtonSelectedStatus() {
        let indexOfButtonShouldBeHighlighted: Int = {
            let currentPosition = currentControllerPosition
            let index = currentPosition.index
            let percentage = currentPosition.percentage
            return percentage > 0.5 ? index + 1 : index
        }()
        guard indexOfButtonShouldBeHighlighted != currentSelectedButtonIndex else {return}
        buttons[currentSelectedButtonIndex].selected = false
        buttons[currentSelectedButtonIndex].tintColor = UIColor.grayColor()
        buttons[indexOfButtonShouldBeHighlighted].selected = true
        buttons[indexOfButtonShouldBeHighlighted].tintColor = UIColor.themeColor
        currentSelectedButtonIndex = indexOfButtonShouldBeHighlighted
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
