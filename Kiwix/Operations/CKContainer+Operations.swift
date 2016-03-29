/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A convenient extension to CloudKit.CKContainer.
*/

#if !os(watchOS)

import CloudKit

extension CKContainer {
    /**
        Verify that the current user has certain permissions for the `CKContainer`,
        and potentially requesting the permission if necessary.
        
        - parameter permission: The permissions to be verified on the container.

        - parameter shouldRequest: If this value is `true` and the user does not 
            have the passed `permission`, then the user will be prompted for it.

        - parameter completion: A closure that will be executed after verification
            completes. The `NSError` passed in to the closure is the result of either
            retrieving the account status, or requesting permission, if either 
            operation fails. If the verification was successful, this value will
        be `nil`.
    */
    func verifyPermission(permission: CKApplicationPermissions, requestingIfNecessary shouldRequest: Bool = false, completion: NSError? -> Void) {
        verifyAccountStatus(self, permission: permission, shouldRequest: shouldRequest, completion: completion)
    }
}

/**
    Make these helper functions instead of helper methods, so we don't pollute
    `CKContainer`.
*/
private func verifyAccountStatus(container: CKContainer, permission: CKApplicationPermissions, shouldRequest: Bool, completion: NSError? -> Void) {
    container.accountStatusWithCompletionHandler { accountStatus, accountError in
        if accountStatus == .Available {
            if permission != CKApplicationPermissions() {
                verifyPermission(container, permission: permission, shouldRequest: shouldRequest, completion: completion)
            }
            else {
                completion(nil)
            }
        }
        else {
            let error = accountError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.NotAuthenticated.rawValue, userInfo: nil)
            completion(error)
        }
    }
}

private func verifyPermission(container: CKContainer, permission: CKApplicationPermissions, shouldRequest: Bool, completion: NSError? -> Void) {
    container.statusForApplicationPermission(permission) { permissionStatus, permissionError in
        if permissionStatus == .Granted {
            completion(nil)
        }
        else if permissionStatus == .InitialState && shouldRequest {
            requestPermission(container, permission: permission, completion: completion)
        }
        else {
            let error = permissionError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.PermissionFailure.rawValue, userInfo: nil)
            completion(error)
        }
    }
}

private func requestPermission(container: CKContainer, permission: CKApplicationPermissions, completion: NSError? -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        container.requestApplicationPermission(permission) { requestStatus, requestError in
            if requestStatus == .Granted {
                completion(nil)
            }
            else {
                let error = requestError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.PermissionFailure.rawValue, userInfo: nil)
                completion(error)
            }
        }
    }
}

#endif
