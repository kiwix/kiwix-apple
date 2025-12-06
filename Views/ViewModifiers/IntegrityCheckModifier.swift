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

enum IntegrityCheckState {
    case running(title: String)
    case stopped
    
    var isRunning: Bool {
        switch self {
        case .running: true
        case .stopped: false
        }
    }
}

struct IntegrityCheck {
    var state: IntegrityCheckState = .stopped
}

// a globaly shared state
// swiftlint:disable:next identifier_name
var IntegrityCheckShared = IntegrityCheck()

/// Makes sure that the whole screen is blocked while
/// the integrity check of the ZIM file is running
struct IntegrityCheckModifier: ViewModifier {
    // using a shared state, so it will propage to new windows
    // opened after the notification has been sent
    @State private var state = IntegrityCheckShared.state
    
    private let integrityCheck = NotificationCenter.default.publisher(for: .zimIntegrityCheck)
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(state.isRunning)
                .opacity(state.isRunning ? 0.36 : 1)
                .onReceive(integrityCheck, perform: onReceived(notification:))
            if case let .running(title) = state {
                VStack(spacing: 32) {
                    Text(LocalString.zim_file_integrity_check_in_progress(withArgs: title))
                    ProgressView()
                }
            }
        }
    }
    
    private func onReceived(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        // stop or start
        if userInfo["isRunning"] as? Bool == false,
           case .running = state {
            update(state: .stopped)
        } else if let title = userInfo["title"] as? String {
            update(state: .running(title: title))
        }
    }
    
    private func update(state newState: IntegrityCheckState) {
        state = newState
        IntegrityCheckShared.state = newState
    }
}
