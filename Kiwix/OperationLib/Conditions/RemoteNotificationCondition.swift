/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)

import UIKit
    
private let RemoteNotificationQueue = OperationQueue()
private let RemoteNotificationName = "RemoteNotificationPermissionNotification"

private enum RemoteRegistrationResult {
    case Token(NSData)
    case Error(NSError)
}

/// A condition for verifying that the app has the ability to receive push notifications.
@available(*, deprecated, message="use Capability(Push(...)) instead")
    
public struct RemoteNotificationCondition: OperationCondition {
    public static let name = "RemoteNotification"
    public static let isMutuallyExclusive = false
    
    static func didReceiveNotificationToken(token: NSData) {
        NSNotificationCenter.defaultCenter().postNotificationName(RemoteNotificationName, object: nil, userInfo: [
            "token": token
        ])
    }
    
    static func didFailToRegister(error: NSError) {
        NSNotificationCenter.defaultCenter().postNotificationName(RemoteNotificationName, object: nil, userInfo: [
            "error": error
        ])
    }
    
    let application: UIApplication
    
    public init(application: UIApplication) {
        self.application = application
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return RemoteNotificationPermissionOperation(application: application, handler: { _ in })
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        /*
            Since evaluation requires executing an operation, use a private operation
            queue.
        */
        RemoteNotificationQueue.addOperation(RemoteNotificationPermissionOperation(application: application) { result in
            switch result {
                case .Token(_):
                    completion(.Satisfied)

                case .Error(let underlyingError):
                    let error = NSError(code: .ConditionFailed, userInfo: [
                        OperationConditionKey: self.dynamicType.name,
                        NSUnderlyingErrorKey: underlyingError
                    ])

                    completion(.Failed(error))
            }
        })
    }
}

/**
    A private `Operation` to request a push notification token from the `UIApplication`.
    
    - note: This operation is used for *both* the generated dependency **and** 
        condition evaluation, since there is no "easy" way to retrieve the push
        notification token other than to ask for it.

    - note: This operation requires you to call either `RemoteNotificationCondition.didReceiveNotificationToken(_:)` or
        `RemoteNotificationCondition.didFailToRegister(_:)` in the appropriate 
        `UIApplicationDelegate` method, as shown in the `AppDelegate.swift` file.
*/
class RemoteNotificationPermissionOperation: Operation {
    let application: UIApplication
    private let handler: RemoteRegistrationResult -> Void
    
    private init(application: UIApplication, handler: RemoteRegistrationResult -> Void) {
        self.application = application
        self.handler = handler

        super.init()
        
        /*
            This operation cannot run at the same time as any other remote notification
            permission operation.
        */
        addCondition(MutuallyExclusive<RemoteNotificationPermissionOperation>())
    }
    
    override func execute() {
        dispatch_async(dispatch_get_main_queue()) {
            let notificationCenter = NSNotificationCenter.defaultCenter()
            
            notificationCenter.addObserver(self, selector: #selector(RemoteNotificationPermissionOperation.didReceiveResponse(_:)), name: RemoteNotificationName, object: nil)
            
            self.application.registerForRemoteNotifications()
        }
    }
    
    @objc func didReceiveResponse(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        let userInfo = notification.userInfo

        if let token = userInfo?["token"] as? NSData {
            handler(.Token(token))
        }
        else if let error = userInfo?["error"] as? NSError {
            handler(.Error(error))
        }
        else {
            fatalError("Received a notification without a token and without an error.")
        }

        finish()
    }
}
    
#endif
