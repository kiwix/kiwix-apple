//
//  ZIMMultiReaderLoading.swift
//  Kiwix
//
//  Created by Chris on 12/25/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension ZIMMultiReader {
    
    // MARK: - Loading System
    
    func data(id: String, contentURLString: String) -> [String: AnyObject]? {
        guard let reader = readers[id] else {return nil}
        return reader.dataWithContentURLString(contentURLString) as? [String: AnyObject]
    }
    
    func pageURLString(articleTitle: String, bookid id: String) -> String? {
        guard let reader = readers[id] else {return nil}
        return reader.pageURLFromTitle(articleTitle)
    }
    
    func mainPageURLString(bookid id: String) -> String? {
        guard let reader = readers[id] else {return nil}
        return reader.mainPageURL()
    }
    
    func randomPageURLString() -> (id: String, contentURLString: String)? {
        var randomPageURLs = [(String, String)]()
        for (id, reader) in readers{
            randomPageURLs.append((id, reader.getRandomPageUrl()))
        }
        
        guard randomPageURLs.count > 0 else {return nil}
        let index = arc4random_uniform(UInt32(randomPageURLs.count))
        return randomPageURLs[Int(index)]
    }
}