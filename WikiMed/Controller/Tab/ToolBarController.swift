//
//  ToolBarController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class ToolBarController: UIViewController {
    private let stackView = UIStackView()
    private let visualView = VisualEffectShadowView()
    weak var delegate: ToolBarControlEvents?
    
    private(set) lazy var back = ToolBarButton(image: #imageLiteral(resourceName: "Left"))
    private(set) lazy var forward = ToolBarButton(image: #imageLiteral(resourceName: "Right"))
    private(set) lazy var home = ToolBarButton(image: #imageLiteral(resourceName: "Home"))
    private(set) lazy var library = ToolBarButton(image: #imageLiteral(resourceName: "Library"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configVisualView()
        configStackView()
        addButtons()
    }
    
    private func configVisualView() {
        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        let constraints = [
            view.topAnchor.constraint(equalTo: visualView.topAnchor, constant: visualView.shadow.blur),
            view.leftAnchor.constraint(equalTo: visualView.leftAnchor, constant: visualView.shadow.blur),
            view.bottomAnchor.constraint(equalTo: visualView.bottomAnchor, constant: -visualView.shadow.blur),
            view.rightAnchor.constraint(equalTo: visualView.rightAnchor, constant: -visualView.shadow.blur)
        ]
        view.addConstraints(constraints)
    }
    
    private func configStackView() {
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let visualContent = visualView.contentView
        visualContent.addSubview(stackView)
        let constraints = [
            visualContent.topAnchor.constraint(equalTo: stackView.topAnchor),
            visualContent.leftAnchor.constraint(equalTo: stackView.leftAnchor),
            visualContent.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            visualContent.rightAnchor.constraint(equalTo: stackView.rightAnchor)
        ]
        visualContent.addConstraints(constraints)
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
        
        if Bundle.main.infoDictionary?["CFBundleName"] as? String == "Kiwix" {
            stackView.addArrangedSubview(ToolBarDivider())
            stackView.addArrangedSubview(library)
            library.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
        }
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
    private let visual = UIVisualEffectView()
    
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
    
    var contentView: UIView {
        get {return visual.contentView}
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
    
    private func addVisualEffectView() {
        visual.effect = UIBlurEffect(style: .extraLight)
        visual.translatesAutoresizingMaskIntoConstraints = false
        visual.layer.cornerRadius = cornerRadius
        visual.layer.masksToBounds = true
        addSubview(visual)
        let constraints = [
            visual.leftAnchor.constraint(equalTo: leftAnchor, constant: shadow.blur),
            visual.topAnchor.constraint(equalTo: topAnchor, constant: shadow.blur),
            visual.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -shadow.blur),
            visual.rightAnchor.constraint(equalTo: rightAnchor, constant: -shadow.blur),
        ]
        addConstraints(constraints)
    }
}

class ToolBarButton: UIButton {
    convenience init(image: UIImage) {
        self.init()
        setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 54, height: 50)
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.clear
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -10, dy: -10).contains(point)
    }
}

class ToolBarDivider: UIView {
    convenience init() {
        self.init(frame: CGRect.zero)
        backgroundColor = UIColor.lightGray
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 1 / UIScreen.main.scale, height: 0)
    }
}
