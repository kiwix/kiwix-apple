//
//  TabControllerProtocol.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

protocol TabController {
    var canGoBack: Bool {get}
    var canGoForward: Bool {get}
    weak var delegate: TabLoadingActivity? {get set}
    
    func goBack()
    func goForward()
    func loadMainPage()
    func load(url: URL)
}

protocol TabLoadingActivity: class {
    func loadingFinished()
}
