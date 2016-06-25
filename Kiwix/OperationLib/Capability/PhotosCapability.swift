//
//  PhotosCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(iOS)

import Foundation
import Photos

public struct Photos: CapabilityType {
    public static let name = "Photos"

    public init() { }
    
    public func requestStatus(completion: CapabilityStatus -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
            case .Authorized: completion(.Authorized)
            case .Denied: completion(.Denied)
            case .Restricted: completion(.NotAvailable)
            case .NotDetermined: completion(.NotDetermined)
        }
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
                case .Authorized: completion(.Authorized)
                case .Denied: completion(.Denied)
                case .Restricted: completion(.NotAvailable)
                case .NotDetermined: completion(.NotDetermined)
            }
        }
    }
}

#endif
