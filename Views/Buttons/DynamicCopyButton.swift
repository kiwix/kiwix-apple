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

private enum ButtonState {
    case document
    case complete
    
    var systemImage: String {
        switch self {
        case .document: "doc.on.doc"
        case .complete: "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .document: Color.accentColor
        case .complete: Color.green
        }
    }
    
    var label: String {
        switch self {
        case .document: LocalString.common_button_copy
        case .complete: LocalString.common_button_copied
        }
    }
}

struct DynamicCopyButton: View {
    let action: () -> Void
    @State private var copyComplete: UInt = 0
    @State private var buttonState: ButtonState = .document
    @State private var systemImage: String = ButtonState.document.systemImage
    
    var body: some View {
        SensoryFeedbackContext({
            Button {
                action()
                copyComplete += 1
            } label: {
                withSymbolEffect(
                    Label(buttonState.label, systemImage: systemImage)
                        .foregroundStyle(buttonState.color)
                )
            }
            // fix for button height changes when the icon is swapped
            .frame(minHeight: 23)
            .onChange(of: copyComplete) {
                Task {
                    // Task.sleep works better than animation delay
                    // this way the icon swaping is in sync
                    buttonState = .complete
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    systemImage = ButtonState.complete.systemImage
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    systemImage = ButtonState.document.systemImage
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        buttonState = .document
                    }
                }
            }
        }, trigger: copyComplete)
    }
    
    @ViewBuilder
    private func withSymbolEffect(_ content: some View) -> some View {
        if #available(iOS 17, macOS 14, *) {
            content
                .contentTransition(.symbolEffect(.replace))
        } else {
            content
        }
    }
}

struct SensoryFeedbackContext<Content: View, T: Equatable>: View {
    private let content: Content
    private let trigger: T
    
    init(@ViewBuilder _ content: () -> Content, trigger: T) {
        self.content = content()
        self.trigger = trigger
    }
    
    var body: some View {
        if #available(iOS 17, macOS 14, *) {
            content
            #if os(iOS)
                .sensoryFeedback(.success, trigger: trigger) { _, _ in true }
            #endif
        } else {
            content
        }
    }
}
