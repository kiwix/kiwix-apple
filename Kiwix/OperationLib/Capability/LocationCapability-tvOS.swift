//
//  LocationCapability-tvOS.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(tvOS)

import Foundation
import CoreLocation

public struct Location: CapabilityType {
    public static let name = "Location"

    public init() { }

    public func requestStatus(completion: CapabilityStatus -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.NotAvailable)
            return
        }
        
        let actual = CLLocationManager.authorizationStatus()
        
        switch actual {
            case .NotDetermined: completion(.NotDetermined)
            case .Restricted: completion(.NotAvailable)
            case .Denied: completion(.Denied)
            case .AuthorizedWhenInUse: completion(.Authorized)
            case .AuthorizedAlways:
                fatalError(".Always should be unavailable on tvOS")
        }
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        Authorizer.authorize(completion)
    }
}

private let Authorizer = LocationAuthorizer()

private class LocationAuthorizer: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private var completion: (CapabilityStatus -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func authorize(completion: CapabilityStatus -> Void) {
        guard self.completion == nil else {
            fatalError("Attempting to authorize location when a request is already in-flight")
        }
        self.completion = completion
        
        let key = "NSLocationWhenInUseUsageDescription"
        manager.requestWhenInUseAuthorization()
        
        // This is helpful when developing an app.
        assert(NSBundle.mainBundle().objectForInfoDictionaryKey(key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
    }
    
    @objc func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if let completion = self.completion where manager == self.manager && status != .NotDetermined {
            self.completion = nil
            
            switch status {
                case .AuthorizedWhenInUse:
                    completion(.Authorized)
                case .Denied:
                    completion(.Denied)
                case .Restricted:
                    completion(.NotAvailable)
                case .AuthorizedAlways:
                    fatalError(".Always should be unavailable on tvOS")
                case .NotDetermined:
                    fatalError("Unreachable due to the if statement, but included to keep clang happy")
            }
        }
    }
    
}

#endif
