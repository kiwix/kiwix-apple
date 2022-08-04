//
//  Patches.swift
//  Kiwix
//
//  Created by Chris Li on 6/11/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Foundation
import SwiftUI

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

#if os(macOS)
enum UserInterfaceSizeClass {
    case compact
    case regular
}
struct HorizontalSizeClassEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserInterfaceSizeClass = .regular
}
struct VerticalSizeClassEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserInterfaceSizeClass = .regular
}
extension EnvironmentValues {
    var horizontalSizeClass: UserInterfaceSizeClass { .regular }
    var verticalSizeClass: UserInterfaceSizeClass { .regular }
}
#endif
