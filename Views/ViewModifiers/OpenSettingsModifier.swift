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
import SwiftUI

@available(macOS 14, *)
struct OpeningSettingsModifier: ViewModifier {
    @Environment(\.openSettings) private var openSettings
    private let navigateToHotspotSettingsPublisher = NotificationCenter.default.publisher(
        for: .navigateToHotSpotSettings
    )
    let updateTabSelection: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(navigateToHotspotSettingsPublisher) { _ in
                updateTabSelection()
                openSettings()
            }
    }
}

// swiftlint:disable:next type_name
struct OpeningSettingsModifier_macOS_13: ViewModifier {
    private let navigateToHotspotSettingsPublisher = NotificationCenter.default.publisher(
        for: .navigateToHotSpotSettings
    )
    let updateTabSelection: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(navigateToHotspotSettingsPublisher) { _ in
                updateTabSelection()
                openSettings()
            }
    }
    
    private func openSettings() {
        // macOS 13 Ventura
        guard let delegate = NSApp.delegate else { return }
        let selector = Selector(("showSettingsWindow:"))
        if delegate.responds(to: selector) {
            delegate.perform(selector, with: nil, with: nil)
        }
    }
}
#endif
