//
//  MainControllerLoading.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

extension MainController {
       
    func load(url: NSURL?) {
        guard let url = url else {return}
        webView.hidden = false
        hideWelcome()
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }
    
    func loadMainPage(id: ZimID) {
        guard let reader = ZimMultiReader.sharedInstance.readers[id] else {return}
        let mainPageURLString = reader.mainPageURL()
        let mainPageURL = NSURL.kiwixURLWithZimFileid(id, contentURLString: mainPageURLString)
        load(mainPageURL)
    }
    
}

