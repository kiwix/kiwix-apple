//
//  PassbookCapability.swift
//  PSOperations
//
//  Created by Dev Team on 10/4/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

#if os(iOS)

import Foundation
import PassKit

public enum Passbook: CapabilityType {
    public static let name = "Passbook"
    
    case ViewPasses
    case AddPasses
    
    public func requestStatus(completion: CapabilityStatus -> Void) {
        switch self {
            case .ViewPasses:
                if PKPassLibrary.isPassLibraryAvailable() {
                    completion(.Authorized)
                } else {
                    completion(.NotAvailable)
                }
            case .AddPasses:
                if PKAddPassesViewController.canAddPasses() {
                    completion(.Authorized)
                } else {
                    completion(.NotAvailable)
                }
        }
    }
    
    public func authorize(completion: CapabilityStatus -> Void) {
        // Since requestStatus() never returns .NotDetermined, this method should never be called
        fatalError("This should never be invoked")
    }
}

#endif
