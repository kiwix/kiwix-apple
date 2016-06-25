/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if !os(tvOS)
    
    import EventKit
    
    /// A condition for verifying access to the user's calendar.
    
    @available(*, deprecated, message="use Capability(EKEntityType....) instead")
    
    public struct CalendarCondition: OperationCondition {
        
        public static let name = "Calendar"
        static let entityTypeKey = "EKEntityType"
        public static let isMutuallyExclusive = false
        
        public let entityType: EKEntityType
        
        public init(entityType: EKEntityType) {
            self.entityType = entityType
        }
        
        public func dependencyForOperation(operation: Operation) -> NSOperation? {
            return CalendarPermissionOperation(entityType: entityType)
        }
        
        public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
            switch EKEventStore.authorizationStatusForEntityType(entityType) {
            case .Authorized:
                completion(.Satisfied)
                
            default:
                // We are not authorized to access entities of this type.
                let error = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey: self.dynamicType.name,
                    self.dynamicType.entityTypeKey: entityType.rawValue
                    ])
                
                completion(.Failed(error))
            }
        }
    }
    
    /**
    `EKEventStore` takes a while to initialize, so we should create
    one and then keep it around for future use, instead of creating
    a new one every time a `CalendarPermissionOperation` runs.
    */
    private let SharedEventStore = EKEventStore()
    
    /**
     A private `Operation` that will request access to the user's Calendar/Reminders,
     if it has not already been granted.
     */
    class CalendarPermissionOperation: Operation {
        let entityType: EKEntityType
        
        init(entityType: EKEntityType) {
            self.entityType = entityType
            super.init()
            addCondition(AlertPresentation())
        }
        
        override func execute() {
            let status = EKEventStore.authorizationStatusForEntityType(entityType)
            
            switch status {
            case .NotDetermined:
                dispatch_async(dispatch_get_main_queue()) {
                    SharedEventStore.requestAccessToEntityType(self.entityType) { granted, error in
                        self.finish()
                    }
                }
                
            default:
                finish()
            }
        }
        
    }
    
#endif
