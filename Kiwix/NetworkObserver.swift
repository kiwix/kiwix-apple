/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Contains the code to manage the visibility of the network activity indicator
*/

import UIKit

/**
    An `OperationObserver` that will cause the network activity indicator to appear
    as long as the `Operation` to which it is attached is executing.
*/
struct NetworkObserver: OperationObserver {
    // MARK: Initilization

    init() { }
    
    func operationDidStart(operation: Operation) {
        dispatch_async(dispatch_get_main_queue()) {
            // Increment the network indicator's "reference count"
            NetworkIndicatorController.sharedIndicatorController.networkActivityDidStart()
        }
    }
    
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) { }
    
    func operationDidFinish(operation: Operation, errors: [NSError]) {
        dispatch_async(dispatch_get_main_queue()) {
            // Decrement the network indicator's "reference count".
            NetworkIndicatorController.sharedIndicatorController.networkActivityDidEnd()
        }
    }
    
}

/// A singleton to manage a visual "reference count" on the network activity indicator.
private class NetworkIndicatorController {
    // MARK: Properties

    static let sharedIndicatorController = NetworkIndicatorController()

    private var activityCount = 0
    
    private var visibilityTimer: Timer?
    
    // MARK: Methods
    
    func networkActivityDidStart() {
        assert(NSThread.isMainThread(), "Altering network activity indicator state can only be done on the main thread.")

        activityCount++
        
        updateIndicatorVisibility()
    }
    
    func networkActivityDidEnd() {
        assert(NSThread.isMainThread(), "Altering network activity indicator state can only be done on the main thread.")
        
        activityCount--
        
        updateIndicatorVisibility()
    }
    
    private func updateIndicatorVisibility() {
        if activityCount > 0 {
            showIndicator()
        }
        else {
            /*
                To prevent the indicator from flickering on and off, we delay the
                hiding of the indicator by one second. This provides the chance
                to come in and invalidate the timer before it fires.
            */
            visibilityTimer = Timer(interval: 1.0) {
                self.hideIndicator()
            }
        }
    }
    
    private func showIndicator() {
        visibilityTimer?.cancel()
        visibilityTimer = nil
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    private func hideIndicator() {
        visibilityTimer?.cancel()
        visibilityTimer = nil
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

/// Essentially a cancellable `dispatch_after`.
class Timer {
    // MARK: Properties

    private var isCancelled = false
    
    // MARK: Initialization

    init(interval: NSTimeInterval, handler: dispatch_block_t) {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * Double(NSEC_PER_SEC)))
        
        dispatch_after(when, dispatch_get_main_queue()) { [weak self] in
            if self?.isCancelled == false {
                handler()
            }
        }
    }
    
    func cancel() {
        isCancelled = true
    }
}