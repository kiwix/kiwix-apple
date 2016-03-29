/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)

import Photos

/// A condition for verifying access to the user's Photos library.
@available(*, deprecated, message="use Capability(Photos()) instead")
    
public struct PhotosCondition: OperationCondition {
    
    public static let name = "Photos"
    public static let isMutuallyExclusive = false
    
    public init() { }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return PhotosPermissionOperation()
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        switch PHPhotoLibrary.authorizationStatus() {
            case .Authorized:
                completion(.Satisfied)

            default:
                let error = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey: self.dynamicType.name
                ])

                completion(.Failed(error))
        }
    }
}

/**
    A private `Operation` that will request access to the user's Photos, if it
    has not already been granted.
*/
class PhotosPermissionOperation: Operation {
    override init() {
        super.init()

        addCondition(AlertPresentation())
    }
    
    override func execute() {
        switch PHPhotoLibrary.authorizationStatus() {
            case .NotDetermined:
                dispatch_async(dispatch_get_main_queue()) {
                    PHPhotoLibrary.requestAuthorization { status in
                        self.finish()
                    }
                }
     
            default:
                finish()
        }
    }
    
}

#endif
