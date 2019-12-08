//
//  TabsController.swift
//  iOS
//
//  Created by Chris Li on 12/7/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

class TabsController: UIViewController {
    let visualView = UIVisualEffectView()
    let dismissGestureRecognizer = UITapGestureRecognizer()
    
    init() {
        if #available(iOS 13.0, *) {
            visualView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            visualView.effect = UIBlurEffect(style: .regular)
        }
        visualView.contentView.addGestureRecognizer(dismissGestureRecognizer)
        
        super.init(nibName: nil, bundle: nil)
        
        dismissGestureRecognizer.addTarget(self, action: #selector(close))
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = visualView
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
}
