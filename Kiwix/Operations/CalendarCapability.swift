//
//  CalendarCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if !os(tvOS)

import Foundation
import EventKit

private let SharedEventStore = EKEventStore()

extension EKEntityType: CapabilityType {
    public static var name: String { return "EKEntityType" }
    
    public func requestStatus(completion: CapabilityStatus -> Void) {
        let status = EKEventStore.authorizationStatusForEntityType(self)
        switch status {
            case .Authorized: completion(.Authorized)
            case .Denied: completion(.Denied)
            case .Restricted: completion(.NotAvailable)
            case .NotDetermined: completion(.NotDetermined)
        }
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        SharedEventStore.requestAccessToEntityType(self) { granted, error in
            if granted {
                completion(.Authorized)
            } else if let error = error {
                completion(.Error(error))
            } else {
                completion(.NotAvailable)
            }
        }
    }
}

#endif
