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

private enum ValidationState {
    case validating(title: String)
    case notValidating
    
    var isValidating: Bool {
        switch self {
        case .validating: true
        case .notValidating: false
        }
    }
}

/// Makes sure that the whole screen is blocked while
/// the validation of the ZIM file is ongoing
struct ValidationModifier: ViewModifier {
    @State private var state = ValidationState.notValidating
    
    private let validateZIM = NotificationCenter.default.publisher(for: .validateZIM)
    
    func body(content: Content) -> some View {
        ZStack {
            if case let .validating(title) = state {
                VStack {
                    Text("Validating \(title)")
                    ProgressView()
                }
            }
            content
                .opacity(state.isValidating ? 0 : 1)
                .onReceive(validateZIM, perform: onReceived(notification:))
        }
    }
    
    private func onReceived(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        // stop or start
        if userInfo["isRunning"] as? Bool == false,
           case .validating = state {
            state = .notValidating
        } else if let title = userInfo["title"] as? String,
                  case .notValidating = state {
            state = .validating(title: title)
        }
    }
}
