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

#if os(iOS)
import CoreData
import Defaults
import SwiftUI

@MainActor
struct RootViewiOS: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var navigation: NavigationViewModel
    @Default(.savedMenuNavigation) private var selection: MenuItem?
    
    var body: some View {
        if horizontalSizeClass == .compact {
            CompactView()
                .task {
                    await onStart(isCompact: true)
                }
        } else {
            SplitViewForiPadContainer()
                .task {
                    await onStart(isCompact: false)
                }
        }
    }
    
    private func onStart(isCompact: Bool) async {
        switch AppType.current {
        case .kiwix:
            await LibraryOperations.reValidate()
            let toRecentTab: Bool = isCompact || selection == nil
            if !DeepLinkService.shared.isRunning(), toRecentTab {
                navigation.navigateToMostRecentTab()
            } else if let selection {
                navigation.currentItem = selection.navigationItem
            }
            LibraryOperations.applyFileBackupSetting()
            DownloadService.shared.restartHeartbeatIfNeeded()
        case let .branded(zimFileURL):
            await LibraryOperations.open(url: zimFileURL)
            await ZimMigration.forCustomApps()
            if !DeepLinkService.shared.isRunning() {
                navigation.navigateToMostRecentTab()
            }
        }
    }
}

#endif
