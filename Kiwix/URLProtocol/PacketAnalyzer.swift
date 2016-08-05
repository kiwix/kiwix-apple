//
//  PacketAnalyzer.swift
//  Kiwix
//
//  Created by Chris Li on 7/18/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class PacketAnalyzer {
    static let sharedInstance = PacketAnalyzer()
    private var listening = false
    private var images = [(data: NSData, url: NSURL)]()
    
    func startListening() {
        listening = true
    }
    
    func stopListening() {
        listening = false
        images.removeAll()
    }
    
    func addImage(data: NSData, url: NSURL) {
        guard listening else {return}
        images.append((data, url))
    }
    
    func chooseImage() -> (data: NSData, url: NSURL)? {
        return images.first
    }
}
