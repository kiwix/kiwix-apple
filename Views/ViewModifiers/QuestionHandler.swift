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

struct ActiveQuestion {
    let text: String
    let yes: String
    let cancel: String
    let didConfirm: () -> Void
    let didDismiss: () -> Void
}

// similar to AlertHandler, but with 2 options to choose from plus a callback
struct QuestionHandler: ViewModifier {
    @State private var activeQuestion: ActiveQuestion?

    private let question = NotificationCenter.default.publisher(for: .question)

    func body(content: Content) -> some View {
        content.onReceive(question) { notification in
            if let questionValue = notification.userInfo?["question"] as? ActiveQuestion {
                activeQuestion = questionValue
            }
        }
        .alert(activeQuestion?.text ?? "", isPresented: Binding<Bool>.constant(activeQuestion != nil)) {
            Button(activeQuestion?.yes ?? "") {
                activeQuestion?.didConfirm()
                activeQuestion = nil
            }
            Button(activeQuestion?.cancel ?? "") {
                activeQuestion?.didDismiss()
                activeQuestion = nil
            }
        }
    }
}
