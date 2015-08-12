//
//  LanguageFilterTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/3/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class LanguageFilterTBVC: UITableViewController {
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var unfilteredLanguages = [Dictionary<String, AnyObject>]()
    var filteredLanguages = [Dictionary<String, AnyObject>]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Languages"
        
        initializeDataSource()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let newLibraryFilteredLanguages = (filteredLanguages as AnyObject).valueForKey("language") as? [String]
        if let libraryFilteredLanguages = Preference.libraryFilteredLanguages {
            if libraryFilteredLanguages != newLibraryFilteredLanguages! {
                Preference.libraryFilteredLanguages = newLibraryFilteredLanguages
            }
        } else {
            Preference.libraryFilteredLanguages = newLibraryFilteredLanguages
        }
    }
    
    func fetchLanguagesAndCount() -> [Dictionary<String, AnyObject>] {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let entity = NSEntityDescription.entityForName("Book", inManagedObjectContext: self.managedObjectContext)
        
        let langAttributeDescription = (entity?.attributesByName["language"])!
        let keyPathExpression = NSExpression(forKeyPath: "idString") //Does not really matter
        let countExpression = NSExpression(forFunction: "count:", arguments: [keyPathExpression])
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "count"
        expressionDescription.expression = countExpression
        expressionDescription.expressionResultType = .Integer16AttributeType
        
        fetchRequest.propertiesToFetch = [langAttributeDescription, expressionDescription]
        fetchRequest.propertiesToGroupBy = [langAttributeDescription]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        do {
            let results = try self.managedObjectContext.executeFetchRequest(fetchRequest)
            return results as! [Dictionary<String, AnyObject>]
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            return [Dictionary<String, AnyObject>]()
        }
    }
    
    func initializeDataSource() {
        unfilteredLanguages = fetchLanguagesAndCount()
        if let filteredLanguageNames = Preference.libraryFilteredLanguages {
            for langDic in unfilteredLanguages {
                let language = langDic["language"] as! String
                if filteredLanguageNames.contains(language) {
                    unfilteredLanguages.removeAtIndex(unfilteredLanguages.indexOf({ (item) -> Bool in
                        return (item["language"] as! String) == language
                    })!)
                    filteredLanguages.append(langDic)
                }
            }
        }
        sortFilteredLanguageArraysByAlphabet()
        sortUnfilteredLanguageArraysByCount()
    }
    
    func sortUnfilteredLanguageArraysByCount() {
        unfilteredLanguages.sortInPlace({ (item1, item2) -> Bool in
            let count1 = item1["count"]?.integerValue
            let count2 = item2["count"]?.integerValue
            return count1 > count2
        })
    }
    
    func sortFilteredLanguageArraysByAlphabet() {
        filteredLanguages.sortInPlace({ (item1, item2) -> Bool in
            let language1 = item1["language"] as? String
            let language2 = item2["language"] as? String
            return language1 < language2
        })
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return filteredLanguages.count > 0 ? 2 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredLanguages.count > 0 {
            return section == 0 ? filteredLanguages.count : unfilteredLanguages.count
        } else {
            return unfilteredLanguages.count
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LanguageFilterCell", forIndexPath: indexPath)
        
        if filteredLanguages.count > 0 && indexPath.section == 0 {
            let dic = filteredLanguages[indexPath.row]
            cell.textLabel?.text = dic["language"] as? String
            cell.detailTextLabel?.text = (dic["count"] as? NSNumber)?.stringValue
            cell.tintColor = nil
        } else {
            let dic = unfilteredLanguages[indexPath.row]
            cell.textLabel?.text = dic["language"] as? String
            cell.detailTextLabel?.text = (dic["count"] as? NSNumber)?.stringValue
            cell.tintColor = UIColor.whiteColor()
        }
        cell.accessoryType = .Checkmark
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if filteredLanguages.count > 0 {
            return section == 0 ? "Showing" : "Hiding"
        } else {
            return "All"
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if filteredLanguages.count > 0 {
            if indexPath.section == 0 {
                unfilteredLanguages.append(filteredLanguages[indexPath.row])
                filteredLanguages.removeAtIndex(indexPath.row)
                sortUnfilteredLanguageArraysByCount()
            } else {
                filteredLanguages.append(unfilteredLanguages[indexPath.row])
                unfilteredLanguages.removeAtIndex(indexPath.row)
                sortFilteredLanguageArraysByAlphabet()
            }
        } else {
            filteredLanguages.append(unfilteredLanguages[indexPath.row])
            unfilteredLanguages.removeAtIndex(indexPath.row)
        }
        
        if filteredLanguages.count > 1 {
            tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, 2)), withRowAnimation: .Automatic)
        } else {
            tableView.reloadData()
        }
    }
}
