//
//  AppDelegate.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: MainController())
        window?.makeKeyAndVisible()
        URLProtocol.registerClass(KiwixURLProtocol.self)
        loadZimFile()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }
    
    private func loadZimFile() {
        guard let resource = Bundle.main.resourceURL,
            let files = try? FileManager.default.contentsOfDirectory(at: resource, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants),
            let zimFile = files.filter({$0.pathExtension == "zim"}).first else {return}
        ZimManager.shared.addBook(url: zimFile)
    }
    
    // MARK: - Core Data
    
    lazy var persistentContainer = CoreDataContainer()
    class var persistentContainer: CoreDataContainer {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }
    
    private func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges { try? context.save() }
    }
}

