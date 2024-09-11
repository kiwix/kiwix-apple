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

import Foundation
import SwiftUI

struct AsyncButtonView<S: View>: View {
    private let action: @MainActor () async -> Void
    private let label: S
    private let loading: S

    @State private var task: Task<Void, Never>?

    var body: some View {
        Button {
            guard task == nil else {
                return
            }
            task = Task {
                await action()
                task = nil
            }
        } label: {
            if task != nil {
                loading
            } else {
                label
            }
        }
    }

    init(action: @MainActor @escaping () async -> Void,
         @ViewBuilder label: @escaping () -> S,
         @ViewBuilder loading: @escaping () -> S) {
        self.action = action
        self.label = label()
        self.loading = loading()
    }
}


struct AsyncButton<S: View>: View {
    private let action: @MainActor () async -> Void
    private let label: S

    @State private var task: Task<Void, Never>?

    var body: some View {
        Button {
            guard task == nil else {
                return
            }
            task = Task {
                await action()
                task = nil
            }
        } label: {
            if task != nil {
                label
                    .opacity(0.25)
                    .overlay {
                        ProgressView()
                    }
                    .animation(.default, value: true)
            } else {
                label
            }
        }
    }

    init(action: @MainActor @escaping () async -> Void, @ViewBuilder label: @escaping () -> S) {
        self.action = action
        self.label = label()
    }
}

#Preview {
    Group {
        AsyncButton {
            try? await Task.sleep(for: .seconds(3))
        } label: {
            Text("Try me!")
        }
    }.frame(minWidth: 200, minHeight: 400)
}
