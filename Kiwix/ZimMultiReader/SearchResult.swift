//
//  SearchResult.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SearchResult: CustomStringConvertible {
    let lowerCaseSearchTerm: String
    let title: String
    let path: ArticlePath
    let bookID: ZimID
    let snippet: String?
    
    let probability: Double? // range: 0.0 - 1.0
    private(set) lazy var distance: Int = {
        // Here we dont use the swift version of levenshtein, because it is slower than the C++ implementation
        //return self.title.lowercaseString.levenshtein(string: self.lowerCaseSearchTerm)
        return ZimReader.levenshtein(self.title.lowercaseString, anotherString: self.lowerCaseSearchTerm)
    }()
    private(set) lazy var score: Double = {
        if let probability = self.probability {
            return WeightFactor.calculate(probability) * Double(self.distance)
        } else {
            return Double(self.distance)
        }
    }()
    
    init?(rawResult: [String: AnyObject], lowerCaseSearchTerm: String) {
        self.lowerCaseSearchTerm = lowerCaseSearchTerm
        let title = (rawResult["title"] as? String) ?? ""
        let path = (rawResult["path"] as? String) ?? ""
        let bookID = (rawResult["bookID"] as? ZimID) ?? ""
        let snippet = rawResult["snippet"] as? String
        
        let probability: Double? = {
            if let probability = (rawResult["probability"] as? NSNumber)?.doubleValue {
                return probability / 100.0
            } else {
                return nil
            }
        }()
        
        self.title = title
        self.path = path
        self.bookID = bookID
        self.snippet = snippet
        self.probability = probability
        
        if title == "" || path == "" || bookID == "" {return nil}
    }
    
    var description: String {
        var parts = [bookID, title]
        if let probability = probability {parts.append("\(probability)%")}
        parts.append("dist: \(distance)")
        return parts.joinWithSeparator(", ")
    }
    
    var rankInfo: String {
        return "(\(distance), \(probability ?? -1), \(String(format: "%.4f", score)))"
    }
}
