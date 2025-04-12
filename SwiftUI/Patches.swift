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
    static let alert = Notification.Name("alert")
    static let openFiles = Notification.Name("openFiles")
    static let openURL = Notification.Name("openURL")
    static let exportFileData = Notification.Name("exportFileData")
    static let saveContent = Notification.Name("saveContent")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    #if os(macOS)
    static let keepOnlyTabs = Notification.Name("keepOnlyTabs")
    static let zimSearch = Notification.Name("zimSearch")
    #endif
    static let goBack = Notification.Name("goBack")
    static let goForward = Notification.Name("goForward")
    #if os(iOS)
    static let openDonations = Notification.Name("openDonations")
    #endif
}

extension UTType {
    static let zimFile = UTType(exportedAs: "org.openzim.zim")
}

extension NotificationCenter {
    @MainActor
    static func openURL(
        _ url: URL,
        inNewTab: Bool = false,
        context: OpenURLContext? = nil
    ) {
        var userInfo: [AnyHashable: Any] = [
            "url": url,
            "inNewTab": inNewTab
        ]
        if let context {
            userInfo["context"] = context
        }
        NotificationCenter.default.post(
            name: .openURL,
            object: nil,
            userInfo: userInfo
        )
    }

    static func openFiles(_ urls: [URL], context: OpenFileContext) {
        NotificationCenter.default.post(name: .openFiles, object: nil, userInfo: ["urls": urls, "context": context])
    }

    static func exportFileData(_ data: FileExportData) {
        NotificationCenter.default.post(name: .exportFileData, object: nil, userInfo: ["data": data])
    }

    static func saveContent(url: URL) {
        NotificationCenter.default.post(name: .saveContent, object: nil, userInfo: ["url": url])
    }

    static func toggleSidebar() {
        NotificationCenter.default.post(name: .toggleSidebar, object: nil, userInfo: nil)
    }

    #if os(macOS)
    @MainActor static func keepOnlyTabs(_ tabIds: Set<NSManagedObjectID>) {
        NotificationCenter.default.post(name: .keepOnlyTabs,
                                        object: nil,
                                        userInfo: ["tabIds": tabIds])
    }
    #endif
    
    #if os(iOS)
    @MainActor static func openDonations() {
        NotificationCenter.default.post(name: .openDonations, object: nil, userInfo: nil)
    }
    #endif
}
