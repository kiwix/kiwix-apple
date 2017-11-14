//
//  TableOfContentController.swift
//  Kiwix
//
//  Created by Chris Li on 11/2/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class PanelController: UIViewController {
    let visualView = VisualEffectShadowView()
    private(set) var mode: PanelMode?
    private var tableOfContent: TableOfContentController?
    private var bookmark: BookmarkController?
    private var history: HistoryController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configVisualView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        tableOfContent = nil
        bookmark = nil
        history = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            visualView.roundingCorners = [.topLeft, .topRight]
            visualView.setNeedsDisplay()
        case .regular:
            visualView.roundingCorners = nil
            visualView.setNeedsDisplay()
        case .unspecified:
            break
        }
    }
    
    private func configVisualView() {
        view.subviews.forEach({ $0.removeFromSuperview() })
        visualView.removeFromSuperview()
        
        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        [view.topAnchor.constraint(equalTo: visualView.topAnchor, constant: visualView.shadow.blur),
         view.leftAnchor.constraint(equalTo: visualView.leftAnchor, constant: visualView.shadow.blur),
         view.bottomAnchor.constraint(equalTo: visualView.bottomAnchor, constant: -visualView.shadow.blur),
         view.rightAnchor.constraint(equalTo: visualView.rightAnchor, constant: -visualView.shadow.blur)].forEach({ $0.isActive = true })
    }
    
    func set(mode: PanelMode?) {
        self.mode = mode
        let visualContent = visualView.contentView
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        visualContent.subviews.forEach({ $0.removeFromSuperview() })
        
        guard let mode = mode else {return}
        let controller: UIViewController = {
            switch mode {
            case .tableOfContent:
                let controller = tableOfContent ?? TableOfContentController()
                tableOfContent = controller
                return controller
            case .bookmark:
                let controller = bookmark ?? BookmarkController()
                bookmark = controller
                return controller
            case .history:
                let controller = history ?? HistoryController()
                history = controller
                return controller
            }
        }()
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        visualContent.addSubview(controller.view)
        [visualContent.topAnchor.constraint(equalTo: controller.view.topAnchor),
         visualContent.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
         visualContent.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
         visualContent.rightAnchor.constraint(equalTo: controller.view.rightAnchor)].forEach({ $0.isActive = true })
        controller.didMove(toParentViewController: self)
    }
}

enum PanelMode {
    case tableOfContent, bookmark, history
}
