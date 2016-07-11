/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import Foundation
import SystemConfiguration
import PSOperations

/**
    This is a condition that performs a very high-level reachability check.
    It does *not* perform a long-running reachability check, nor does it respond to changes in reachability.
    Reachability is evaluated once when the operation to which this is attached is asked about its readiness.
*/
struct ReachabilityCondition: OperationCondition {
    static let hostKey = "Host"
    static let name = "Reachability"
    static let isMutuallyExclusive = false
    
    let host: NSURL
    let allowCellular: Bool
    
    init(host: NSURL, allowCellular: Bool = true) {
        self.host = host
        self.allowCellular = allowCellular
    }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        ReachabilityController.requestReachability(host, allowCellular: allowCellular) { reachable in
            if reachable {
                completion(.Satisfied)
            }
            else {
                let userInfo = ["title": "Network Error",
                    "message": "Unable connecting to the internet. Please check your connection."]
                let error = NSError(code: .ConditionFailed, userInfo: userInfo)
                completion(.Failed(error))
            }
        }
    }
    
}

/// A private singleton that maintains a basic cache of `SCNetworkReachability` objects.
private class ReachabilityController {
    static var reachabilityRefs = [String: SCNetworkReachability]()

    static let reachabilityQueue = dispatch_queue_create("Operations.Reachability", DISPATCH_QUEUE_SERIAL)
    
    static func requestReachability(url: NSURL?, allowCellular: Bool, completionHandler: (Bool) -> Void) {
        if let host = url?.host {
            dispatch_async(reachabilityQueue) {
                var ref = self.reachabilityRefs[host]

                if ref == nil {
                    let hostString = host as NSString
                    ref = SCNetworkReachabilityCreateWithName(nil, hostString.UTF8String)
                }
                
                if let ref = ref {
                    self.reachabilityRefs[host] = ref
                    
                    let reachable = getReachibility(ref, allowCellular: allowCellular)
                    completionHandler(reachable)
                } else {
                    completionHandler(false)
                }
            }
        } else {
            // Test for general internet connectibility
            dispatch_async(reachabilityQueue) {
                var zeroAddress = sockaddr_in()
                zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
                zeroAddress.sin_family = sa_family_t(AF_INET)
                
                guard let ref = withUnsafePointer(&zeroAddress, {
                    SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
                }) else {completionHandler(false); return}
                
                let reachable = getReachibility(ref, allowCellular: allowCellular)
                completionHandler(reachable)
            }
        }
    }
    
    static func getReachibility(ref: SCNetworkReachability, allowCellular: Bool) -> Bool {
        var reachable = false
        var flags: SCNetworkReachabilityFlags = []
        if SCNetworkReachabilityGetFlags(ref, &flags) != false {
            /*
            Here to check forother considerations,
            such as whether or not the connection would require
            VPN, a cellular connection, etc.
            */
            #if os(iOS) || os(watchOS) || os(tvOS)
                if allowCellular {
                    reachable = flags.contains(.Reachable)
                } else {
                    reachable = flags.contains(.Reachable) && !flags.contains(.IsWWAN)
                }
            #elseif os(OSX)
                return flags.contains(.Reachable)
            #endif
            
        }
        return reachable
    }
}
