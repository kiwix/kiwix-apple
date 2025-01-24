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

struct NotFocusable: ViewModifier {
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.focusable(false)
        #else
        content
        #endif
    }
}

struct Focusable<Value: Hashable>: ViewModifier {
    
    private let value: Value
    private let focusState: FocusState<Value>.Binding
    private let onReturn: () -> Void
    private let onDissmiss: () -> Void
    
    init(
        _ binding: FocusState<Value>.Binding,
        equals value: Value,
        onReturn: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.focusState = binding
        self.value = value
        self.onReturn = onReturn
        self.onDissmiss = onDismiss
    }
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .id(value)
            .focusable()
            .focused(focusState, equals: value)
            .modifier(KeyPressHandler(key: .return, action: {
                onReturn()
            }))
            .modifier(KeyPressHandler(key: .escape, action: {
                onDissmiss()
            }))
        #else
        content
        #endif
        
    }
}
