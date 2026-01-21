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

enum FeatureFlags {
#if DEBUG
    static let map: Bool = true
#else
    static let map: Bool = false
#endif
    /// Custom apps, which have a bundled zim file, do not require library access
    /// this will remove all library related features
    static let hasLibrary: Bool = !AppType.isCustom

    static let showExternalLinkOptionInSettings: Bool = Config.value(for: .showExternalLinkSettings) ?? true
    // Revert this once we solve:
    // https://github.com/kiwix/libkiwix/issues/1265
    static let showSearchSnippetInSettings: Bool = false // Config.value(for: .showSearchSnippetInSettings) ?? true
    
    static let suggestSearchTerms: Bool = Config.value(for: .showSearchSuggestionsSpellChecked) ?? false
}
