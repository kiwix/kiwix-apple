//
//  LocationCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(iOS) || os(watchOS)

import Foundation
import CoreLocation

public enum Location: CapabilityType {
    public static let name = "Location"
    
    case WhenInUse
    case Always
    
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
            case .AuthorizedAlways: completion(.Authorized)
            case .AuthorizedWhenInUse:
                if self == .WhenInUse {
                    completion(.Authorized)
                } else {
                    // the user wants .Always, but has .WhenInUse
                    // return .NotDetermined so that we can prompt to upgrade the permission
                    completion(.NotDetermined)
                }
        }
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        Authorizer.authorize(self, completion: completion)
    }
}
    
private let Authorizer = LocationAuthorizer()
    
private class LocationAuthorizer: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private var completion: (CapabilityStatus -> Void)?
    private var kind = Location.WhenInUse
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func authorize(kind: Location, completion: CapabilityStatus -> Void) {
        guard self.completion == nil else {
            fatalError("Attempting to authorize location when a request is already in-flight")
        }
        self.completion = completion
        self.kind = kind
        
        let key: String
        switch kind {
            case .WhenInUse:
                key = "NSLocationWhenInUseUsageDescription"
                manager.requestWhenInUseAuthorization()
                
            case .Always:
                key = "NSLocationAlwaysUsageDescription"
                manager.requestAlwaysAuthorization()
        }
        
        // This is helpful when developing an app.
        assert(NSBundle.mainBundle().objectForInfoDictionaryKey(key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
    }
    
    @objc func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if let completion = self.completion where manager == self.manager && status != .NotDetermined {
            self.completion = nil
            
            switch status {
                case .AuthorizedAlways:
                    completion(.Authorized)
                case .AuthorizedWhenInUse:
                    completion(kind == .WhenInUse ? .Authorized : .Denied)
                case .Denied:
                    completion(.Denied)
                case .Restricted:
                    completion(.NotAvailable)
                case .NotDetermined:
                    fatalError("Unreachable due to the if statement, but included to keep clang happy")
            }
        }
    }
    
}

#endif
