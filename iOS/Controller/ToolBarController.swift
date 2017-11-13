//
//  ToolBarController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class ToolBarController: UIViewController {
    let visualView = VisualEffectShadowView()
    private let stackView = UIStackView()
    weak var delegate: ToolBarControlEvents?
    
    private(set) lazy var back = ToolBarButton(image: #imageLiteral(resourceName: "Left"))
    private(set) lazy var forward = ToolBarButton(image: #imageLiteral(resourceName: "Right"))
    private(set) lazy var home = ToolBarButton(image: #imageLiteral(resourceName: "Home"), insets: UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
    private(set) lazy var tableOfContent = ToolBarButton(image: #imageLiteral(resourceName: "TableOfContent"), insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
    private(set) lazy var star = ToolBarButton(image: #imageLiteral(resourceName: "Star"), insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configVisualView()
        configStackView()
        addButtons()
    }
    
    private func configVisualView() {
        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            view.topAnchor.constraint(equalTo: visualView.topAnchor, constant: visualView.shadow.blur),
            view.bottomAnchor.constraint(equalTo: visualView.bottomAnchor, constant: -visualView.shadow.blur)])
    }
    
    private func configStackView() {
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let visualContent = visualView.contentView
        visualContent.addSubview(stackView)
        NSLayoutConstraint.activate([
            visualContent.topAnchor.constraint(equalTo: stackView.topAnchor),
            visualContent.leftAnchor.constraint(equalTo: stackView.leftAnchor),
            visualContent.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            visualContent.rightAnchor.constraint(equalTo: stackView.rightAnchor)])
    }
    
    private func addButtons() {
        let buttons = [back, forward, home, tableOfContent, star]
        buttons.forEach { (button) in
            stackView.addArrangedSubview(button)
            button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
            if button != buttons.last {
                stackView.addArrangedSubview(ToolBarDivider())
            }
        }
    }
    
    @objc func buttonTapped(button: UIButton) {
        switch button {
        case back:
            delegate?.backButtonTapped()
        case forward:
            delegate?.forwardButtonTapped()
        case tableOfContent:
            delegate?.tableOfContentButtonTapped()
        case star:
            delegate?.bookmarkButtonTapped()
        case home:
            delegate?.homeButtonTapped()
        default:
            return
        }
    }
}

protocol ToolBarControlEvents: class {
    func backButtonTapped()
    func forwardButtonTapped()
    func tableOfContentButtonTapped()
    func bookmarkButtonTapped()
    func homeButtonTapped()
}

class ToolBarButton: UIButton {
    convenience init(image: UIImage, insets: UIEdgeInsets = .zero) {
        self.init()
        imageEdgeInsets = insets
        imageView?.contentMode = .scaleAspectFit
        setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        imageView?.layer.cornerRadius = 4
        imageView?.clipsToBounds = true
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.clear
        }
    }
    
    override var isSelected: Bool {
        didSet {
            imageView?.tintColor = isSelected ? UIColor.white : nil
            imageView?.backgroundColor = isSelected ? #colorLiteral(red: 0, green: 0.431372549, blue: 1, alpha: 1) : UIColor.clear
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 54, height: 50)
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
