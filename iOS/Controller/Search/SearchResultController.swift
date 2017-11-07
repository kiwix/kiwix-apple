//
//  SearchResultController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class SearchResultController: UIViewController {
    private let visualView = VisualEffectShadowView()
    private let searchResultView = SearchResultView()
    private let constraints = Constraints()
    private var observer: NSKeyValueObservation?
    
    override func loadView() {
        view = SearchResultControllerBackgroundView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observer = view.observe(\.hidden, options: .new, changeHandler: { (view, change) in
            if change.newValue == true { view.isHidden = false }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: .UIKeyboardDidHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidHide, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        if traitCollection.horizontalSizeClass == .regular {
            configureForHorizontalRegular()
        } else if traitCollection.horizontalSizeClass == .compact {
            configureForHorizontalCompact()
        }
    }
    
    @objc func keyboardWillShow(notification: Notification)  {
        searchResultView.isHidden = true
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSValue],
            let origin = userInfo[UIKeyboardFrameEndUserInfoKey]?.cgRectValue.origin else {return}
        let point = searchResultView.convert(origin, from: nil)
        searchResultView.bottomInset = searchResultView.frame.height - point.y
        searchResultView.isHidden = false
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        searchResultView.isHidden = true
        searchResultView.bottomInset = 0
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        searchResultView.isHidden = false
    }
    
    private func configureForHorizontalCompact() {
        NSLayoutConstraint.deactivate(constraints.horizontalRegular)
        view.subviews.forEach({ $0.removeFromSuperview() })
        searchResultView.removeFromSuperview()
        
        searchResultView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultView)
        if constraints.horizontalCompact.count == 0 {
            constraints.horizontalCompact = {
                if #available(iOS 11.0, *) {
                    return [searchResultView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                            searchResultView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                            searchResultView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                            searchResultView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)]
                } else {
                    return [searchResultView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                            searchResultView.leftAnchor.constraint(equalTo: view.leftAnchor),
                            searchResultView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                            searchResultView.rightAnchor.constraint(equalTo: view.rightAnchor)]
                }
            }()
        }
        
        NSLayoutConstraint.activate(constraints.horizontalCompact)
    }
    
    private func configureForHorizontalRegular() {
        NSLayoutConstraint.deactivate(constraints.horizontalCompact)
        view.subviews.forEach({ $0.removeFromSuperview() })

        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        searchResultView.translatesAutoresizingMaskIntoConstraints = false
        visualView.contentView.addSubview(searchResultView)
        if constraints.horizontalRegular.count == 0 {
            var constraints = [visualView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                               visualView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75),
                               visualView.widthAnchor.constraint(lessThanOrEqualToConstant: 800)]
            let widthConstraint = visualView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75)
            widthConstraint.priority = .defaultHigh
            constraints.append(widthConstraint)
            
            if #available(iOS 11.0, *) {
                constraints.append(visualView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -visualView.shadow.blur))
            } else {
                constraints.append(visualView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: -visualView.shadow.blur))
            }
            
            constraints += [visualView.contentView.topAnchor.constraint(equalTo: searchResultView.topAnchor),
                            visualView.contentView.leftAnchor.constraint(equalTo: searchResultView.leftAnchor),
                            visualView.contentView.bottomAnchor.constraint(equalTo: searchResultView.bottomAnchor),
                            visualView.contentView.rightAnchor.constraint(equalTo: searchResultView.rightAnchor)]
            
            self.constraints.horizontalRegular = constraints
        }
        
        NSLayoutConstraint.activate(constraints.horizontalRegular)
    }
    
    class SearchResultControllerBackgroundView: UIView {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            return subviews.map({ $0.frame.contains(point) }).reduce(false, { $0 || $1 })
        }
    }
    
    class Constraints {
        var horizontalRegular = [NSLayoutConstraint]()
        var horizontalCompact = [NSLayoutConstraint]()
    }
}

