//
//  Patches.swift
//  Kiwix
//
//  Created by Chris Li on 6/11/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

extension SwiftUI.View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        modifier(self)
    }
}

/// Brings size classes to macOS, with regular as defaults
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
    var horizontalSizeClass: UserInterfaceSizeClass {
        get { self[HorizontalSizeClassEnvironmentKey.self] }
        set { self[HorizontalSizeClassEnvironmentKey.self] = newValue }
    }
    var verticalSizeClass: UserInterfaceSizeClass {
        get { return self[VerticalSizeClassEnvironmentKey.self] }
        set { self[VerticalSizeClassEnvironmentKey.self] = newValue }
    }
}
#endif

/// Ports theme adaptive background colors to SwiftUI
extension Color {
    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #elseif os(iOS)
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
}

extension Notification.Name {
    static let openURL = Notification.Name("openURL")
    static let articleLoadingAlert = Notification.Name("articleLoadingAlert")
}

extension UTType {
    static let zimFile = UTType(exportedAs: "org.openzim.zim")
}

extension NotificationCenter {
    static func openURL(_ url: URL?) {
        guard let url else { return }
        NotificationCenter.default.post(name: Notification.Name.openURL, object: nil, userInfo: ["url": url])
    }
}
