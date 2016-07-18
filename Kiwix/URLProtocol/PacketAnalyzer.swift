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
    private var images = [NSData]()
    
    func startListening() {
        listening = true
    }
    
    func stopListening() {
        listening = false
        images.removeAll()
    }
    
    func addImage(data: NSData) {
        guard listening else {return}
        images.append(data)
    }
    
    func chooseImage() -> NSData? {
        return images.first
    }
}
