//
//  ControllerRetainer.swift
//  Kiwix
//
//  Created by Chris Li on 8/31/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class ControllerRetainer {
    static let shared = ControllerRetainer()
    private init() {}
    
    private var libraryStore: UIViewController?
    private func releaseLibrary() {libraryStore = nil}
    
    var library: UIViewController {
        let controller = libraryStore ?? UIStoryboard.library.instantiateInitialViewController()
        libraryStore = controller
        return controller!
    }
    
    func didDismissLibrary() {
        if #available(iOS 10, *) {
            NSTimer.scheduledTimerWithTimeInterval(120.0, repeats: false, block: { (timer) in
                print("set nil")
                self.libraryStore = nil
            })
        } else {
            NSTimer.scheduledTimerWithTimeInterval(120.0, target: self, selector: Selector("releaseLibrary"), userInfo: nil, repeats: false)
        }
    }

}
