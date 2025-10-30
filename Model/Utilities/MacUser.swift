// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

#if os(macOS)
import Foundation
import CoreServices

enum MacUser {
    static func logIsUserAdmin() {
        let backgroundQueue = DispatchQueue(label: "org.kiwix.macuser_background", qos: .background)
        backgroundQueue.async {
            let isAdmin = isAdmin()
            Log.Environment.notice("MacUser isAdmin: \(isAdmin)")
        }
    }
    
    private static func isAdmin() -> Bool {
        guard let currentIdentity = currentUserIdentity(),
              let adminGroup = adminGroupIdentity() else {
            return false
        }
        return CSIdentityIsMemberOfGroup(currentIdentity, adminGroup)
    }
    
    private static func currentUserIdentity() -> CSIdentity? {
        guard let query = CSIdentityQueryCreateForCurrentUser(nil) else {
            Log.Environment.warning("\(#line) cannot get current mac user")
            return nil
        }
        let queryRef = query.takeRetainedValue()
        guard CSIdentityQueryExecute(queryRef, 0, nil) else {
            Log.Environment.warning("\(#line) cannot execute query for mac user")
            return nil
        }
        guard let groups = CSIdentityQueryCopyResults(queryRef).takeRetainedValue() as? [CSIdentity],
              !groups.isEmpty else {
            Log.Environment.warning("\(#line) no group found for mac user")
            return nil
        }
        
        return groups.first
    }
    
    private static func adminGroupIdentity() -> CSIdentity? {
        let defaultAthority = CSGetDefaultIdentityAuthority().takeRetainedValue()
        guard let query = CSIdentityQueryCreateForName(
            nil,
            "admin" as CFString,
            kCSIdentityQueryStringEquals,
            kCSIdentityClassGroup,
            defaultAthority
        ) else {
            Log.Environment.warning("\(#line) cannot query admin user group")
            return nil
        }
        let queryRef = query.takeRetainedValue()
        defer {
            CSIdentityQueryStop(queryRef)
        }
        guard CSIdentityQueryExecute(queryRef, 0, nil) else {
            Log.Environment.warning("\(#line) cannot execute query for admin user group")
            return nil
        }
        guard let groups = CSIdentityQueryCopyResults(queryRef).takeRetainedValue() as? [CSIdentity],
              !groups.isEmpty else {
            Log.Environment.warning("\(#line) no group found for query")
            return nil
        }
        return groups.first
    }
}

#endif
