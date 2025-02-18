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

struct ArticleActions: View {
    
    let zimFileID: UUID
    
    var body: some View {
        AsyncButton {
            guard let url = await ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
            NotificationCenter.openURL(url, inNewTab: true)
        } label: {
            Label(LocalString.library_zim_file_context_main_page_label, systemImage: "house")
        }
        AsyncButton {
            guard let url = await ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
            NotificationCenter.openURL(url, inNewTab: true)
        } label: {
            Label(LocalString.library_zim_file_context_random_label, systemImage: "die.face.5")
        }
    }
}
