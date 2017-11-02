//
//  PanelController.swift
//  Kiwix
//
//  Created by Chris Li on 11/1/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class PanelController: UIViewController {
    let visualView = VisualEffectShadowView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configVisualView()
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

}
