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
        var buttons = [back, forward, home]
        if Bundle.main.infoDictionary?["CFBundleName"] as? String == "Kiwix" {
            buttons.append(library)
            library.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        }
        
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
        case home:
            delegate?.homeButtonTapped()
        case library:
            delegate?.libraryButtonTapped()
        default:
            return
        }
    }
}

protocol ToolBarControlEvents: class {
    func backButtonTapped()
    func forwardButtonTapped()
    func homeButtonTapped()
    func libraryButtonTapped()
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
