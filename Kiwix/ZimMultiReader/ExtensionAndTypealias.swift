//
//  ExtensionAndTypealias.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

typealias ZimID = String
typealias ArticlePath = String

extension ZimReader {
    var metaData: [String: AnyObject] {
        var metadata = [String: AnyObject]()
        
        if let id = getID() {metadata["id"] = id}
        if let title = getTitle() {metadata["title"] = title}
        if let description = getDesc() {metadata["description"] = description}
        if let creator = getCreator() {metadata["creator"] = creator}
        if let publisher = getPublisher() {metadata["publisher"] = publisher}
        if let favicon = getFavicon() {metadata["favicon"] = favicon}
        if let date = getDate() {metadata["date"] = date}
        if let articleCount = getArticleCount() {metadata["articleCount"] = articleCount}
        if let mediaCount = getMediaCount() {metadata["mediaCount"] = mediaCount}
        if let fileSize = getFileSize() {metadata["size"] = fileSize}
        if let langCode = getLanguage() {metadata["language"] = langCode}
        
        return metadata
    }
}

// https://gist.github.com/adamyanalunas/69f6601fad6040686d300a1cdc20f500
private extension String {
    subscript(index: Int) -> Character {
        return self[startIndex.advancedBy(index)]
    }
    
    subscript(range: Range<Int>) -> String {
        let start = startIndex.advancedBy(range.startIndex)
        let end = startIndex.advancedBy(range.endIndex)
        return self[start..<end]
    }
}

extension String {
    func levenshtein(string cmpString: String) -> Int {
        let (length, cmpLength) = (characters.count, cmpString.characters.count)
        var matrix = Array(
            count: cmpLength + 1,
            repeatedValue: Array(
                count: length + 1,
                repeatedValue: 0
            )
        )
        
        for m in 1..<cmpLength {
            matrix[m][0] = matrix[m - 1][0] + 1
        }
        
        for n in 1..<length {
            matrix[0][n] = matrix[0][n - 1] + 1
        }
        
        for m in 1..<(cmpLength + 1) {
            for n in 1..<(length + 1) {
                let penalty = self[n - 1] == cmpString[m - 1] ? 0 : 1
                let (horizontal, vertical, diagonal) = (matrix[m - 1][n] + 1, matrix[m][n - 1] + 1, matrix[m - 1][n - 1])
                matrix[m][n] = min(horizontal, vertical, diagonal + penalty)
            }
        }
        
        return matrix[cmpLength][length]
    }
}