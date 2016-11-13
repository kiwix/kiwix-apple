//
//  SearchBar.swift
//  SearchBar
//
//  Created by Chris Li on 9/2/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class SearchBar: UIView {
    
    let backgroundView = SearchBarBackgroundView()
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private(set) var textField: UITextField = SearchBarTextField()
    
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
    
    convenience init(textField: UITextField) {
        self.init(frame: CGRect.zero)
        self.textField = textField
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
        textField.textColor = UIColor.black
        textField.becomeFirstResponder()
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - 
    
    func textFieldDidEndEditing() {
        textField.isUserInteractionEnabled = false
        textField.textColor = UIColor.darkGray
    }
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
        font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular + 0.1)
        autocorrectionType = .no
        autocapitalizationType = .none
        clearButtonMode = .whileEditing
    }
    
    override var text: String? {
        didSet {
            let size = CGSize(width: 1000, height: 28)
            let rect = text?.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
            print(rect)
        }
    }
    
    // MARK: - Rect overrides
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.offsetBy(dx: 50, dy: 1)
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
    
    // MARK: - Animations
    
    func animateIn() {
        isAnimatingIn = true
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.backgroundColor = UIColor.gray
            }) { (completed) in
                self.isAnimatingIn = false
                guard !self.isTouching else {return}
                self.animateOut()
        }
    }
    
    func animateOut() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: {
            self.backgroundColor = UIColor.lightGray
            }) { (completed) in
        }
    }
}

extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: 1000, height: 28)
        
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.height
    }
}
