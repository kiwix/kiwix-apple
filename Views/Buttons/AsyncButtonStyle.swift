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

public protocol AsyncButtonStyle {
    associatedtype Label: View
    associatedtype Button: View
    typealias LabelConfiguration = AsyncButtonStyleLabelConfiguration
    typealias ButtonConfiguration = AsyncButtonStyleButtonConfiguration

    @ViewBuilder func makeLabel(configuration: LabelConfiguration) -> Label
    @ViewBuilder func makeButton(configuration: ButtonConfiguration) -> Button
}

public struct AsyncButtonStyleLabelConfiguration {
    typealias Label = AnyView

    let isLoading: Bool
    let label: Label
    let cancel: () -> Void
}

public struct AsyncButtonStyleButtonConfiguration {
    typealias Button = AnyView

    let isLoading: Bool
    let button: Button
    let cancel: () -> Void
}
