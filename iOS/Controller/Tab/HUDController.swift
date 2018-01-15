//
//  MessageController.swift
//  iOS
//
//  Created by Chris Li on 1/15/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class HUDController: UIViewController {
    let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    
    override func loadView() {
        view = visualView
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        configure()
//    }
//    
//    private func configure() {
//        visualView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(visualView)
//        NSLayoutConstraint.activate([
//            view.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
//            view.centerYAnchor.constraint(equalTo: visualView.centerYAnchor),
//            visualView.widthAnchor.constraint(equalToConstant: 400),
//            visualView.heightAnchor.constraint(equalToConstant: 400)])
//    }
}
