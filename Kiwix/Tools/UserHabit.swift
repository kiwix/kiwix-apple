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
        let interval = timeAppDidBecomeActive?.timeIntervalSinceNow
        print(interval)
    }
}
