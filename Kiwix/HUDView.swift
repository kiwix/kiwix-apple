//
//  HUDView.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class HUDView: UIView {
    let horizontalInset: CGFloat = 20.0
    let verticalInset: CGFloat = 10.0
    let cornerRadius: CGFloat = {
        if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) {
            return 12.0
        } else {
            return 8.0
        }
    }()
    
    let dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let visualEffectView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
        let visualEffectView = UIVisualEffectView(effect: effect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        return visualEffectView
    }()
    
    var addedConstraints = [NSLayoutConstraint]()
    
    var subView: UIView = UIView()
    var superView: UIView = UIView()
    
    // MARK: - Add
    
    func add() {
        for view in superView.subviews {
            if view.isKindOfClass(UIVisualEffectView) {return}
        }
        
        //superView.addSubview(dimmedView)
        superView.addSubview(visualEffectView)
        self.addSubview(subView)
        superView.insertSubview(self, aboveSubview: visualEffectView)
        
        //setupDimmedView()
        setupVisiualEffectView()
        setupSubView()
        setupSelf()
        setupGestureRecognizer()
        
        self.transform = CGAffineTransformMakeScale(1.2, 1.2)
        self.visualEffectView.transform = CGAffineTransformMakeScale(1.2, 1.2)
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            //self.dimmedView.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
            self.transform = CGAffineTransformMakeScale(1.0, 1.0)
            self.visualEffectView.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }) { (completed) -> Void in
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.8 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                    self.dismiss()
                }
        }
    }
    
    // MARK: - Setups
    
    func setupDimmedView() {
        let views = ["DimmedView": dimmedView]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[DimmedView]|", options: .AlignAllLeft, metrics: nil, views: views)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[DimmedView]|", options: .AlignAllLeft, metrics: nil, views: views)
        superView.addConstraints(hConstraints + vConstraints)
        addedConstraints += (hConstraints + vConstraints)
    }
    
    func setupVisiualEffectView() {
        let views = ["VisualEffectView": visualEffectView, "SuperView": superView]
        let metrics = ["VisiualEffectViewHeight": subView.frame.height + 2*verticalInset, "VisiualEffectViewWidth": subView.frame.width + 2*horizontalInset]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[SuperView]-(<=1)-[VisualEffectView(VisiualEffectViewHeight)]", options: .AlignAllCenterX, metrics: metrics, views: views)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:[SuperView]-(<=1)-[VisualEffectView(VisiualEffectViewWidth)]", options: .AlignAllCenterY, metrics: metrics, views: views)
        superView.addConstraints(hConstraints + vConstraints)
        addedConstraints += (hConstraints + vConstraints)
        
        let mask = CAShapeLayer()
        let rect = CGRectMake(0, 0, metrics["VisiualEffectViewWidth"]!, metrics["VisiualEffectViewHeight"]!)
        mask.path = UIBezierPath(roundedRect: CGRectMake(rect.minX, rect.minY, rect.width, rect.height), cornerRadius: cornerRadius).CGPath
        visualEffectView.layer.mask = mask
    }
    
    func setupSelf() {
        self.translatesAutoresizingMaskIntoConstraints = false
        let views = ["Self": self, "SuperView": superView]
        let metrics = ["SelfHeight": subView.frame.height + 2*verticalInset, "SelfWidth": subView.frame.width + 2*horizontalInset]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[SuperView]-(<=1)-[Self(SelfHeight)]", options: .AlignAllCenterX, metrics: metrics, views: views)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:[SuperView]-(<=1)-[Self(SelfWidth)]", options: .AlignAllCenterY, metrics: metrics, views: views)
        superView.addConstraints(hConstraints + vConstraints)
        addedConstraints += (hConstraints + vConstraints)
        
        let mask = CAShapeLayer()
        let rect = CGRectMake(0, 0, metrics["SelfWidth"]!, metrics["SelfHeight"]!)
        mask.path = UIBezierPath(roundedRect: CGRectMake(rect.minX, rect.minY, rect.width, rect.height), cornerRadius: cornerRadius).CGPath
        self.layer.mask = mask
    }
    
    func setupSubView() {
        subView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["Self": self, "SubView": subView]
        let metrics = ["VerticalInset": verticalInset, "HorizontalInset": horizontalInset]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(VerticalInset)-[SubView]-(VerticalInset)-|", options: .AlignAllCenterX, metrics: metrics, views: views)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(HorizontalInset)-[SubView]-(HorizontalInset)-|", options: .AlignAllCenterY, metrics: metrics, views: views)
        self.addConstraints(hConstraints + vConstraints)
    }
    
    func setupGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismiss")
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - Dismiss
    
    func dismiss() {
        self.removeFromSuperview()
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            self.transform = CGAffineTransformMakeScale(1.2, 1.2)
            self.visualEffectView.transform = CGAffineTransformMakeScale(1.2, 1.2)
            self.visualEffectView.alpha = 0.0
            //self.dimmedView.backgroundColor = UIColor.clearColor()
            for view in self.subviews {
                view.alpha = 0.0
            }
            
            for view in self.subView.subviews {
                view.alpha = 0.0
            }
            
            }) { (completed) -> Void in
                if completed {
                    
                    self.visualEffectView.removeFromSuperview()
                    //self.dimmedView.removeFromSuperview()
                    self.superView.removeConstraints(self.addedConstraints)
                }
        }
    }
    
    // MARK: - Override
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.clearColor()
    }
    
    convenience init(superView: UIView, message: String) {
        self.init()
        let label = UILabel()
        label.textAlignment = .Center
        label.text = message
        label.sizeToFit()
        self.superView = superView
        self.subView = label
    }
    
}
