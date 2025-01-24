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

import SwiftUI

enum MoveDirection: Sendable {
    
    // swiftlint:disable:next identifier_name
    case up
    case down
    case left
    case right
    
    #if os(macOS)
    init?(from direction: MoveCommandDirection) {
        switch direction {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        @unknown default: return nil
        }
    }
    #endif
}

struct MoveCommand: ViewModifier {
    
    private let action: ((MoveDirection) -> Void)?
    
    init(perform action: ((MoveDirection) -> Void)?) {
        self.action = action
    }
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onMoveCommand { (direction: MoveCommandDirection) in
            if let mappedDirection = MoveDirection(from: direction) {
                action?(mappedDirection)
            }
        }
        #else
        content
        #endif
    }
}
