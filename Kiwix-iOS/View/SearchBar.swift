//
//  SearchBar.swift
//  SearchBar
//
//  Created by Chris Li on 9/2/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class SearchBar: UIView, UITextFieldDelegate {
    
    private let backgroundView = SearchBarBackgroundView()
    private let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let textField: UITextField = SearchBarTextField()
    
    let delayTextChangeCallback = true
    weak var delegate: SearchBarDelegate?
    private var cachedSearchText: String?
    private var previousSearchText = ""
    var title = "" {
        didSet {
            if !isFirstResponder {textField.text = title}
        }
    }
    
    // MARK: - Overrides
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        guard let superview = newSuperview else {return}
        frame = CGRect(x: 0, y: 0, width: superview.frame.width, height: superview.frame.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview = superview else {return}
        let midx = superview.bounds.midX
        
        var left = superview.bounds.origin.x
        var right = superview.bounds.origin.x + superview.bounds.width
        
        for view in superview.subviews {
            guard view.alpha > 0 else { continue }
            left = view.frame.maxX < midx ? max(left, view.frame.maxX) : left
            right = view.frame.minX > midx ? min(right, view.frame.minX) : right
        }
        
        frame = CGRect(x: left, y: 0, width: right - left, height: superview.bounds.height).insetBy(dx: 10, dy: 0)
    }
    
    // MARK: -
    
    func setup() {
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(backgroundView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: .alignAllCenterY, metrics: nil, views: ["view": backgroundView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[view]-|", options: .alignAllCenterX, metrics: nil, views: ["view": backgroundView]))
        
        backgroundView.addSubview(visualEffectView)

        addSubview(textField)
        textField.delegate = self
        textField.returnKeyType = .go
        textField.isUserInteractionEnabled = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[view]-|", options: .alignAllCenterY, metrics: nil, views: ["view": textField]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[view]-|", options: .alignAllCenterX, metrics: nil, views: ["view": textField]))
    }
    
    func textDidChange(textField: UITextField) {
        guard let searchText = textField.text else {return}
        if delayTextChangeCallback {
            guard self.cachedSearchText != searchText else {return}
            self.cachedSearchText = searchText
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(275 * USEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                guard searchText == self.cachedSearchText else {return}
                self.delegate?.textDidChange(text: searchText, searchBar: self)
            }
        } else {
            cachedSearchText = searchText
            delegate?.textDidChange(text: searchText, searchBar: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return delegate?.shouldReturn(searchBar: self) ?? false
    }
    
    // MARK: - Responder
    
    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        textField.isUserInteractionEnabled = true
        textField.textAlignment = .left
        textField.becomeFirstResponder()
        title = textField.text ?? ""
        textField.text = previousSearchText
        delegate?.didBecomeFirstResponder(searchBar: self)
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        textField.isUserInteractionEnabled = false
        textField.textAlignment = .center
        textField.resignFirstResponder()
        previousSearchText = textField.text ?? ""
        textField.text = title
        delegate?.didResignFirstResponder(searchBar: self)
        return true
    }
}

private class SearchBarTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    func setup() {
        placeholder = "Search"
        addTarget(superview, action: #selector(SearchBar.textDidChange(textField:)), for: .editingChanged)
        
        autocorrectionType = .no
        autocapitalizationType = .none
        clearButtonMode = .whileEditing
        
        font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium)
        textColor = UIColor.darkText
        setValue(UIColor.gray, forKeyPath: "_placeholderLabel.textColor")
        
        textAlignment = .center
        contentVerticalAlignment = .center
    }
    
    // MARK: - Rect overrides
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.offsetBy(dx: 0, dy: 1)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).insetBy(dx: 4, dy: 0).offsetBy(dx: 0, dy: 1)
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return super.leftViewRect(forBounds: bounds).offsetBy(dx: -2, dy: 0)
    }
    
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        return super.clearButtonRect(forBounds: bounds).offsetBy(dx: 10, dy: 0)
    }
}

private class SearchBarBackgroundView: UIView {
    
    var isTouching = false
    var isAnimatingIn = false
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.lightGray
        alpha = 0.3
        layer.cornerRadius = 4.0
        layer.masksToBounds = true
    }
    
    // MARK: - Override
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = true
        animateIn()
        _ = (superview as? SearchBar)?.becomeFirstResponder()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        guard !isAnimatingIn else {return}
        animateOut()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let frame = self.bounds.insetBy(dx: -6, dy: -12)
        return frame.contains(point) ? self : nil
    }
    
    // MARK: - Animations
    
    func animateIn() {
        isAnimatingIn = true
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.backgroundColor = UIColor.darkGray
        }) { (completed) in
            self.isAnimatingIn = false
            guard !self.isTouching else {return}
            self.animateOut()
        }
    }
    
    func animateOut() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: {
            self.backgroundColor = UIColor.lightGray
        }, completion: nil)
    }
}

// MARK: - SearchBarDelegate

protocol SearchBarDelegate: class {
    func didBecomeFirstResponder(searchBar: SearchBar)
    func didResignFirstResponder(searchBar: SearchBar)
    func textDidChange(text: String, searchBar: SearchBar)
    func shouldReturn(searchBar: SearchBar) -> Bool
}
