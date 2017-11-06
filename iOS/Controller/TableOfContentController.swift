//
//  TableOfContentController.swift
//  Kiwix
//
//  Created by Chris Li on 11/2/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TableOfContentController: UIViewController {
    let visualView = VisualEffectShadowView(roundingCorners: [.topLeft, .topRight])
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.delegate = self
//        tableView.dataSource = self
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            configForHorizontalCompact()
        case .regular:
            configForHorizontalRegular()
        case .unspecified:
            break
        }
    }
    
    private func configForHorizontalCompact() {
        view.subviews.forEach({ $0.removeFromSuperview() })
        [visualView, tableView].forEach({ $0.removeFromSuperview() })
        
        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        [view.topAnchor.constraint(equalTo: visualView.topAnchor, constant: visualView.shadow.blur),
         view.leftAnchor.constraint(equalTo: visualView.leftAnchor, constant: visualView.shadow.blur),
         view.bottomAnchor.constraint(equalTo: visualView.bottomAnchor, constant: -visualView.shadow.blur),
         view.rightAnchor.constraint(equalTo: visualView.rightAnchor, constant: -visualView.shadow.blur)].forEach({ $0.isActive = true })
        
        let visualContent = visualView.contentView
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        visualContent.addSubview(tableView)
        [visualContent.topAnchor.constraint(equalTo: tableView.topAnchor),
         visualContent.leftAnchor.constraint(equalTo: tableView.leftAnchor),
         visualContent.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
         visualContent.rightAnchor.constraint(equalTo: tableView.rightAnchor)].forEach({ $0.isActive = true })
    }
    
    private func configForHorizontalRegular() {
        view.subviews.forEach({ $0.removeFromSuperview() })
        tableView.removeFromSuperview()
        
        tableView.backgroundColor = .white
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addConstraints([
            view.topAnchor.constraint(equalTo: tableView.topAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            view.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            view.rightAnchor.constraint(equalTo: tableView.rightAnchor)])
    }
}
