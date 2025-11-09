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
import SwiftUI

struct ContentSearchBar: View {

    @ObservedObject private var viewModel: ContentSearchViewModel

    @State private var isActivated: Bool = false
    @FocusState private var focusedState: Bool

    init(model: ContentSearchViewModel) {
        viewModel = model
    }

    var body: some View {
        if isActivated {
            field
                .focused($focusedState)
                .onKeyPress(.escape) {
                    dismiss()
                    return .handled
                }
        } else {
            button
                .keyboardShortcut("f", modifiers: .command)
            /// special hidden button to trigger the top bar zim file search with cmd+shift+F
            Button {
                NotificationCenter.default.post(name: .zimSearch, object: nil)
            } label: {
                Text("")
            }
            .hidden()
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }
    }
    
    private func dismiss() {
        viewModel.reset()
        isActivated = false
    }

    private var button: some View {
        Button {
            isActivated = true
            focusedState = true
        } label: {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 18))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(24)
    }

    private var field: some View {
        HStack {
            searchImage
            TextField(LocalString.common_search, text: $viewModel.contentSearchText)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 2) {
                leftButton
                rightButton
            }
            closeButton
        }
        .padding(8)
        .background(Color.background)
        .padding(16)
        .cornerRadius(16)
        .frame(maxWidth: 320)
    }

    private var searchImage: some View {
        Image(systemName: "magnifyingglass")
            .foregroundColor(.primary)
    }

    private var leftButton: some View {
        Button {
            Task { await viewModel.findPrevious() }
        } label: {
            Image(systemName: "arrowshape.left").foregroundColor(.primary)
        }
        .keyboardShortcut("g", modifiers: EventModifiers(arrayLiteral: .command, .shift))
    }

    private var rightButton: some View {
        Button {
            Task { await viewModel.findNext() }
        } label: {
            Image(systemName: "arrowshape.right").foregroundColor(.primary)
        }
        .keyboardShortcut("g")
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill").foregroundColor(.primary)
        }
    }

}
#endif
