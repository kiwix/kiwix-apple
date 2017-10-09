//
//  ToolBarController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class ToolBarController: UIViewController {
    let stackView = UIStackView()
    weak var delegate: ToolBarControlEvents?
    
    private(set) lazy var back = ToolBarButton(imageName: "Left")
    private(set) lazy var forward = ToolBarButton(imageName: "Right")
    private(set) lazy var home = ToolBarButton(imageName: "Home")
    
    override func loadView() {
        view = VisualEffectShadowView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addStackView()
        addButtons()
    }
    
    private func addStackView() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let visualContent = (view as! VisualEffectShadowView).visualEffectView.contentView
        visualContent.addSubview(stackView)
        visualContent.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[stack]|", options: [], metrics: nil, views: ["stack": stackView]))
        visualContent.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stack]|", options: [], metrics: nil, views: ["stack": stackView]))
    }
    
    private func addButtons() {
        stackView.addArrangedSubview(back)
        stackView.addArrangedSubview(ToolBarDivider())
        stackView.addArrangedSubview(forward)
        stackView.addArrangedSubview(ToolBarDivider())
        stackView.addArrangedSubview(home)
        
        back.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
        forward.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
        home.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(button: UIButton) {
        if button == back {
            delegate?.backButtonTapped()
        } else if button == forward {
            delegate?.forwardButtonTapped()
        } else if button == home {
            delegate?.homeButtonTapped()
        }
    }
}

protocol ToolBarControlEvents: class {
    func backButtonTapped()
    func forwardButtonTapped()
    func homeButtonTapped()
}

class VisualEffectShadowView: UIView {
    struct Shadow {
        let offset: CGSize
        let blur: CGFloat
        let color: UIColor
    }
    
    let shadow = Shadow(offset: CGSize.zero, blur: 4.0, color: .lightGray)
    let cornerRadius: CGFloat = 10.0
    let visualEffectView = UIVisualEffectView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    private func configure() {
        backgroundColor = UIColor.clear
        addVisualEffectView()
    }
    
    override func draw(_ rect: CGRect) {
        let contentRect = rect.insetBy(dx: shadow.blur, dy: shadow.blur)
        let shadowPath = UIBezierPath(roundedRect: contentRect, cornerRadius: cornerRadius)
        let context = UIGraphicsGetCurrentContext()!
        
        context.addRect(rect)
        context.addPath(shadowPath.cgPath)
        context.clip(using: .evenOdd)
        
        context.addPath(shadowPath.cgPath)
        context.setShadow(offset: CGSize.zero, blur: shadow.blur, color: shadow.color.cgColor)
        context.fillPath()
    }
    
    func addVisualEffectView() {
        visualEffectView.effect = UIBlurEffect(style: .extraLight)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.layer.cornerRadius = cornerRadius
        visualEffectView.layer.masksToBounds = true
        addSubview(visualEffectView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(radius)-[visual]-(radius)-|", options: [], metrics: ["radius": shadow.blur], views: ["visual": visualEffectView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(radius)-[visual]-(radius)-|", options: [], metrics: ["radius": shadow.blur], views: ["visual": visualEffectView]))
    }
}

class ToolBarButton: UIButton {
    convenience init(imageName: String) {
        self.init()
        setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 50, height: 50)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.backgroundColor = UIColor.clear
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.backgroundColor = UIColor.clear
    }
}

class ToolBarDivider: UIView {
    convenience init() {
        self.init(frame: CGRect.zero)
        backgroundColor = UIColor.lightGray
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 1 / UIScreen.main.scale, height: 50)
    }
}
