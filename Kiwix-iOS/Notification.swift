//
//  Notifications.swift
//  Kiwix
//
//  Created by Chris Li on 9/19/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UserNotifications

class AppNotification: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotification()
    private override init() {}
    
    func register() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _ in }
    }
    
    func downloadFinished(bookID: String, bookTitle: String, fileSizeDescription: String) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            guard settings.alertSetting == .enabled else {return}
            let content = UNMutableNotificationContent()
            content.categoryIdentifier = "org.kiwix.download-finished"
            content.title = bookTitle + " is downloaded!"
            content.body = fileSizeDescription + " has been transferred."
            let request = UNNotificationRequest(identifier: "org.kiwix.download-finished." + bookID, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        })
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
        
    
}
