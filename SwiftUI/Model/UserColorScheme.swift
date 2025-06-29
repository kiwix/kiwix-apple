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

enum UserColorScheme: Int, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: Int {
        rawValue
    }
    
    var name: String {
        switch self {
        case .light: return LocalString.theme_settings_option_light
        case .dark: return LocalString.theme_settings_option_dark
        case .system: return LocalString.theme_settings_option_system
        }
    }
    
    #if os(iOS)
    var asUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
    #endif
    
    #if os(macOS)
    var asNSAppearance: NSAppearance? {
        switch self {
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        case .system: return nil
        }
    }
    
    #endif
}

final class UserColorSchemeStore: ObservableObject {
    
    @AppStorage("userColorScheme") var userColorScheme: UserColorScheme = .system {
        didSet {
            update()
        }
    }
    
    #if os(iOS)
    func update() {
        keyWindow?.overrideUserInterfaceStyle = userColorScheme.asUserInterfaceStyle
    }

    private var keyWindow: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
              let window = windowSceneDelegate.window else {
            return nil
        }
        return window
    }
    #endif
    
    #if os(macOS)
    func update() {
        NSApplication.shared.appearance = userColorScheme.asNSAppearance ?? NSAppearance.currentDrawing()
    }
    #endif
    
}
