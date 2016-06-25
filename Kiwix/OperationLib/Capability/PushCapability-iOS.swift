//
//  PushCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(iOS)

import UIKit
    
public struct Push: CapabilityType {
    
    public static func didReceiveToken(token: NSData) {
        authorizer.completeAuthorization(token, error: nil)
    }
    
    public static func didFailRegistration(error: NSError) {
        authorizer.completeAuthorization(nil, error: error)
    }

    public static let name = "Push"
    
    public init(application: UIApplication) {
        if authorizer.application == nil {
            authorizer.application = application
        }
    }
    
    public func requestStatus(completion: CapabilityStatus -> Void) {
        if let _ = authorizer.token {
            completion(.Authorized)
        } else {
            completion(.NotDetermined)
        }
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        authorizer.authorize(completion)
    }
    
}

private let authorizer = PushAuthorizer()
    
private class PushAuthorizer {
    
    var application: UIApplication?
    var token: NSData?
    var completion: (CapabilityStatus -> Void)?
    
    func authorize(completion: CapabilityStatus -> Void) {
        guard self.completion == nil else {
            fatalError("Cannot request push authorization while a request is already in progress")
        }
        
        self.completion = completion
        
        guard let application = application else {
            fatalError("An application has not yet been configured, so this won't work")
        }
        
        application.registerForRemoteNotifications()
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
