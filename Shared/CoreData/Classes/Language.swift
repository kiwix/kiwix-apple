//
//  Language.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import Foundation
import CoreData


class Language: NSManagedObject {

    class func fetchOrAdd(_ code: String, context: NSManagedObjectContext) -> Language? {
        let code = Locale.canonicalLanguageIdentifier(from: code)

        if let language = fetch(code, context: context) {
            return language
        }
        
        let language = Language(context: context)
        language.code = code
        language.name = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.languageCode, value: code)
        return language
    }
    
    class func fetch(_ code: String, context: NSManagedObjectContext) -> Language? {
        let request = Language.fetchRequest() as! NSFetchRequest<Language>
        request.predicate = NSPredicate(format: "code == %@", code)
        return (try? context.fetch(request))?.first
    }
    
    class func fetch(displayed: Bool, context: NSManagedObjectContext) -> [Language] {
        let request = Language.fetchRequest() as! NSFetchRequest<Language>
        request.predicate = NSPredicate(format: "isDisplayed == %@", NSNumber(value: displayed))
        return (try? context.fetch(request)) ?? [Language]()
    }
    
    class func fetchAll(_ context: NSManagedObjectContext) -> [Language] {
        let request = Language.fetchRequest() as! NSFetchRequest<Language>
        return (try? context.fetch(request)) ?? [Language]()
    }
    
    // MARK: - Computed Properties
    
    var nameInCurrentLocale: String? {
        return (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: code)
    }
    
    var nameInOriginalLocale: String? {
        return (Locale(identifier: code) as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: code)
    }
}
