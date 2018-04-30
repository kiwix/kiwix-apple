//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

class LibraryController: UIViewController {
    private var currentMode: Mode?
    private var changeToken: NotificationToken?
    private let zimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            return database.objects(ZimFile.self)
        } catch { return nil }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDatabaseObserver()
    }
    
    private func configureDatabaseObserver() {
        changeToken = zimFiles?.observe({ (changes) in
            switch changes {
            case .initial(let results), .update(let results, _, _, _):
                if results.count > 0  {
                    guard self.currentMode != .split else {return}
                    self.setChild(controller: LibrarySplitController())
                    self.currentMode = .split
                } else {
                    guard self.currentMode != .onboarding else {return}
                    let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LibraryOnboardingController")
                    self.setChild(controller: UINavigationController(rootViewController: controller))
                    self.currentMode = .onboarding
                }
            default:
                break
            }
        })
    }
    
    private func setChild(controller: UIViewController) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
            view.rightAnchor.constraint(equalTo: controller.view.rightAnchor),
            view.topAnchor.constraint(equalTo: controller.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)])
        controller.didMove(toParentViewController: self)
    }
    
    enum Mode {
        case onboarding, split
    }
}
