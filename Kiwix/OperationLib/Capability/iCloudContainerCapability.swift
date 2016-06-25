//
//  CloudCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if !os(watchOS)

import Foundation
import CloudKit

public struct iCloudContainer: CapabilityType {
    
    public static let name = "iCloudContainer"
    
    private let container: CKContainer
    private let permissions: CKApplicationPermissions
    
    public init(container: CKContainer, permissions: CKApplicationPermissions = []) {
        self.container = container
        self.permissions = permissions
    }
    
    public func requestStatus(completion: CapabilityStatus -> Void) {
        verifyAccountStatus(container, permission: permissions, shouldRequest: false, completion: completion)
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        verifyAccountStatus(container, permission: permissions, shouldRequest: true, completion: completion)
    }
    
}

private func verifyAccountStatus(container: CKContainer, permission: CKApplicationPermissions, shouldRequest: Bool, completion: CapabilityStatus -> Void) {
    container.accountStatusWithCompletionHandler { accountStatus, accountError in
        switch accountStatus {
            case .NoAccount: completion(.NotAvailable)
            case .Restricted: completion(.NotAvailable)
            case .CouldNotDetermine:
                let error = accountError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.NotAuthenticated.rawValue, userInfo: nil)
                completion(.Error(error))
            case .Available:
                if permission != [] {
                    verifyPermission(container, permission: permission, shouldRequest: shouldRequest, completion: completion)
                } else {
                    completion(.Authorized)
                }
        }
    }
}

private func verifyPermission(container: CKContainer, permission: CKApplicationPermissions, shouldRequest: Bool, completion: CapabilityStatus -> Void) {
    container.statusForApplicationPermission(permission) { permissionStatus, permissionError in
        switch permissionStatus {
            case .InitialState:
                if shouldRequest {
                    requestPermission(container, permission: permission, completion: completion)
                } else {
                    completion(.NotDetermined)
                }
            case .Denied: completion(.Denied)
            case .Granted: completion(.Authorized)
            case .CouldNotComplete:
                let error = permissionError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.PermissionFailure.rawValue, userInfo: nil)
                completion(.Error(error))
        }
    }
}

private func requestPermission(container: CKContainer, permission: CKApplicationPermissions, completion: CapabilityStatus -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        container.requestApplicationPermission(permission) { requestStatus, requestError in
            switch requestStatus {
                case .InitialState: completion(.NotDetermined)
                case .Denied: completion(.Denied)
                case .Granted: completion(.Authorized)
                case .CouldNotComplete:
                    let error = requestError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.PermissionFailure.rawValue, userInfo: nil)
                    completion(.Error(error))
            }
        }
    }
}

#endif
