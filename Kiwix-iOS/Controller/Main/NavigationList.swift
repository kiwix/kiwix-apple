//
//  NavigationStack.swift
//  Kiwix
//
//  Created by Chris Li on 11/20/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class NavigationList {
    var backList = [URL]()
    var forwardList = [URL]()
    var currentURL: URL?
    
    func webViewFinishedLoading(url: URL) {
        guard url != currentURL else { return }
    }
    
    func goBack() {
        
    }
    
    func goForward() {
        
    }
    
    var canGoBack: Bool {
        return false
    }
    
    var canGoForward: Bool {
        return false
    }

}
