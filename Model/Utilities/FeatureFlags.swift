//  Copyright © 2023 Kiwix.

import Foundation

enum FeatureFlags {
#if DEBUG
    static let wikipediaDarkUserCSS: Bool = true
    static let map: Bool = true
#else
    static let wikipediaDarkUserCSS: Bool = false
    static let map: Bool = false
#endif
    /// Custom apps, which have a bundled zim file, do not require library access
    /// this will remove all library related features
    static let hasLibrary: Bool = !AppType.isCustom

    static let showExternalLinkOptionInSettings: Bool = Config.value(for: .showExternalLinkSettings) ?? true
    static let showSearchSnippetInSettings: Bool = Config.value(for: .showSearchSnippetInSettings) ?? true
}
