//
//  UserHabit.swift
//  Kiwix
//
//  Created by Chris Li on 2/2/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class UserHabit {
    static let shared = UserHabit()
    private init() {}
    
    // MARK: - App Become Active
    
    private var timeAppDidBecomeActive: Date?
    
    func appDidBecomeActive() {
        timeAppDidBecomeActive = Date()
    }
    
    func appWillResignActive() {
        // if app stay active for more than 10s, record this as an active session
        guard let timeAppDidBecomeActive = timeAppDidBecomeActive,
            timeAppDidBecomeActive.timeIntervalSinceNow * -1 > 10 else {return}
        
        if let lastDate = Preference.Rate.activeHistory.last {
            if timeAppDidBecomeActive.timeIntervalSince(lastDate) > 24 * 3600 {
                Preference.Rate.activeHistory.append(timeAppDidBecomeActive)
            }
        } else {
            Preference.Rate.activeHistory.append(timeAppDidBecomeActive)
        }
        print("ActiveUse: \(Preference.Rate.activeHistory)")
    }
}
