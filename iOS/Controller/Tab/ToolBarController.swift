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
    
//    private(set) lazy var back = TabToolbarButton(image: #imageLiteral(resourceName: "Left"))
//    private(set) lazy var forward = TabToolbarButton(image: #imageLiteral(resourceName: "Right"))
//    private(set) lazy var home = TabToolbarButton(image: #imageLiteral(resourceName: "Home"), insets: UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
//    private(set) lazy var tableOfContent = TabToolbarButton(image: #imageLiteral(resourceName: "TableOfContent"), insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
//    private(set) lazy var bookmark = TabToolbarButton(image: #imageLiteral(resourceName: "Star"), insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configVisualView()
        configStackView()
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
    
    func set(buttons: [TabToolbarButton]) {
        stackView.arrangedSubviews.forEach({ stackView.removeArrangedSubview($0) })
        buttons.forEach { (button) in
            stackView.addArrangedSubview(button)
//            button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
            if button != buttons.last {
                stackView.addArrangedSubview(ToolBarDivider())
            }
        }
    }
    
    @objc func buttonTapped(button: UIButton) {
//        switch button {
//        case back:
//            delegate?.backButtonTapped()
//        case forward:
//            delegate?.forwardButtonTapped()
//        case tableOfContent:
//            delegate?.tableOfContentButtonTapped()
//        case bookmark:
//            delegate?.bookmarkButtonTapped()
//        case home:
//            delegate?.homeButtonTapped()
//        default:
//            return
//        }
    }
}

protocol ToolBarControlEvents: class {
    func backButtonTapped()
    func forwardButtonTapped()
    func tableOfContentButtonTapped()
    func bookmarkButtonTapped()
    func homeButtonTapped()
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
