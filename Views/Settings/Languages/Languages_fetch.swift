// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import CoreData
import Defaults

enum Languages {
    /// Retrieve a list of languages.
    /// - Returns: languages with count of zim files in each language
    static func fetch() async -> [Language] {
        let languages: [Language] = await Database.shared.viewContext.perform {
            let count = NSExpressionDescription()
            count.name = "count"
            count.expression = NSExpression(
                forFunction: "count:",
                arguments: [NSExpression(forKeyPath: "languageCode")]
            )
            count.expressionResultType = .integer16AttributeType
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ZimFile")
            // exclude the already downloaded files, they might have invalid language set
            // but we are mainly interested in fetched content
            fetchRequest.predicate = ZimFile.Predicate.notDownloaded()
            fetchRequest.propertiesToFetch = ["languageCode", count]
            fetchRequest.propertiesToGroupBy = ["languageCode"]
            fetchRequest.resultType = .dictionaryResultType
            
            guard let results = try? fetchRequest.execute() else {
                return []
            }
            let collector = LanguageCollector()
            for result in results {
                if let result = result as? NSDictionary,
                   let languageCodes = result["languageCode"] as? String,
                   let count = result["count"] as? Int {
                    collector.addLanguages(codes: languageCodes, count: count)
                }
            }
            return collector.languages()
        }
        return languages
    }
}
