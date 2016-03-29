//
//  HealthCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(iOS) || os(watchOS)

import Foundation
import HealthKit

public struct Health: CapabilityType {
    public static let name = "Health"
    
    private let readTypes: Set<HKSampleType>
    private let writeTypes: Set<HKSampleType>
    
    public init(typesToRead: Set<HKSampleType>, typesToWrite: Set<HKSampleType>) {
        self.readTypes = typesToRead
        self.writeTypes = typesToWrite
    }
    
    public func requestStatus(completion: CapabilityStatus -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.NotAvailable)
            return
        }
        
        let notDeterminedTypes = writeTypes.filter { SharedHealthStore.authorizationStatusForType($0) == .NotDetermined }
        if notDeterminedTypes.isEmpty == false {
            completion(.NotDetermined)
            return
        }
        
        let deniedTypes = writeTypes.filter { SharedHealthStore.authorizationStatusForType($0) == .SharingDenied }
        if deniedTypes.isEmpty == false {
            completion(.Denied)
            return
        }
        
        // if we get here, then every write type has been authorized
        // there's no way to know if we have read permissions,
        // so the best we can do is see if we've ever asked for authorization
        
        let unrequestedReadTypes = readTypes.subtract(requestedReadTypes)
        
        if unrequestedReadTypes.isEmpty == false {
            completion(.NotDetermined)
            return
        }
        
        // if we get here, then there was nothing to request for reading or writing
        // thus, everything is authorized
        completion(.Authorized)
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.NotAvailable)
            return
        }
        
        // make a note that we've requested these types before
        requestedReadTypes.unionInPlace(readTypes)
        
        // This method is smart enough to not re-prompt for access if it has already been granted.
        SharedHealthStore.requestAuthorizationToShareTypes(writeTypes, readTypes: readTypes) { _, error in
            if let error = error {
                completion(.Error(error))
            } else {
                self.requestStatus(completion)
            }
        }
    }
    
}

/**
    HealthKit does not report on whether or not you're allowed to read certain data types.
    Instead, we'll keep track of which types we've already request to read. If a new request
    comes along for a type that's not in here, we know that we'll need to re-prompt for
    permission to read that particular type.
*/
private var requestedReadTypes = Set<HKSampleType>()
private let SharedHealthStore = HKHealthStore()

#endif
