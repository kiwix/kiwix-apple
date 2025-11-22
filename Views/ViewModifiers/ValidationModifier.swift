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

enum ValidationState {
    case validating(title: String)
    case notValidating
    
    var isValidating: Bool {
        switch self {
        case .validating: true
        case .notValidating: false
        }
    }
}

struct Validation {
    var state: ValidationState = .notValidating
}
// a globally shared state
var ValidationShared = Validation()

/// Makes sure that the whole screen is blocked while
/// the validation of the ZIM file is ongoing
struct ValidationModifier: ViewModifier {
    // using a shared state, so it will propage to new windows
    // opened after the notification has been sent
    @State private var state = ValidationShared.state
    
    private let validateZIM = NotificationCenter.default.publisher(for: .validateZIM)
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(state.isValidating)
                .opacity(state.isValidating ? 0.36 : 1)
                .onReceive(validateZIM, perform: onReceived(notification:))
            if case let .validating(title) = state {
                VStack(spacing: 32) {
                    Text("Validating \(title) ...")
                    ProgressView()
                }
            }
        }
    }
    
    private func onReceived(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        // stop or start
        if userInfo["isRunning"] as? Bool == false,
           case .validating = state {
            update(state: .notValidating)
        } else if let title = userInfo["title"] as? String,
                  case .notValidating = state {
            update(state: .validating(title: title))
        }
    }
    
    private func update(state newState: ValidationState) {
        state = newState
        ValidationShared.state = newState
    }
}
