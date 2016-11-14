//
//  SearchBar.swift
//  SearchBar
//
//  Created by Chris Li on 9/2/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

protocol SearchBarDelegate: class {
    func didBecomeFIrstResponder()
    func didResignFirstResponder()
}

class SearchBar: UIView {
    
    private let backgroundView = SearchBarBackgroundView()
    private let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let textField: UITextField = SearchBarTextField()
    weak var delegate: SearchBarDelegate?
    
    // MARK: - Initialization
    
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
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidEndEditing, object: textField)
    }
    
    func setup() {
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(backgroundView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: .alignAllCenterY, metrics: nil, views: ["view": backgroundView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[view]-|", options: .alignAllCenterX, metrics: nil, views: ["view": backgroundView]))
        
        backgroundView.addSubview(visualEffectView)

        addSubview(textField)
        textField.isUserInteractionEnabled = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[view]-|", options: .alignAllCenterY, metrics: nil, views: ["view": textField]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[view]-|", options: .alignAllCenterX, metrics: nil, views: ["view": textField]))
        
        NotificationCenter.default.addObserver(self, selector: #selector(SearchBar.textFieldDidEndEditing), name: .UITextFieldTextDidEndEditing, object: textField)
    }
    
    // MARK: - Responder
    
    override func becomeFirstResponder() -> Bool {
        textField.isUserInteractionEnabled = true
        textField.becomeFirstResponder()
        delegate?.didBecomeFIrstResponder()
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
        delegate?.didResignFirstResponder()
        return true
    }
    
    // MARK: - 
    
    func textFieldDidEndEditing() {
        textField.isUserInteractionEnabled = false
    }
    
    class SearchBarTextField: UITextField {
        
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
    
    class SearchBarBackgroundView: UIView {
        
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
}

