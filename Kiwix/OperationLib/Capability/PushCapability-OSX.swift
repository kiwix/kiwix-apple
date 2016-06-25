//
//  PushCapability-OSX.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(OSX)

import Cocoa

public struct Push: CapabilityType {
    
    public static func didReceiveToken(token: NSData) {
        authorizer.completeAuthorization(token, error: nil)
    }
    
    public static func didFailRegistration(error: NSError) {
        authorizer.completeAuthorization(nil, error: error)
    }
    
    public static let name = "Push"
    
    private let types: NSRemoteNotificationType
    
    public init(types: NSRemoteNotificationType) {
        self.types = types
    }
    
    public func requestStatus(completion: CapabilityStatus -> Void) {
        if let _ = authorizer.token {
            completion(.Authorized)
        } else {
            completion(.NotDetermined)
        }
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        authorizer.authorize(types, completion: completion)
    }
    
}

private let authorizer = PushAuthorizer()

private class PushAuthorizer {
    
    var token: NSData?
    var completion: (CapabilityStatus -> Void)?
    
    func authorize(types: NSRemoteNotificationType, completion: CapabilityStatus -> Void) {
        guard self.completion == nil else {
            fatalError("Cannot request push authorization while a request is already in progress")
        }
        
        self.completion = completion
        NSApplication.sharedApplication().registerForRemoteNotificationTypes(types)
    }
    
    private func completeAuthorization(token: NSData?, error: NSError?) {
        self.token = token
        
        guard let completion = self.completion else { return }
        self.completion = nil
        
        if let _ = self.token {
            completion(.Authorized)
        } else if let error = error {
            completion(.Error(error))
        } else {
            completion(.NotDetermined)
        }
    }
    
}

#endif
