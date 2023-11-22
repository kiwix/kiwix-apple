//  Copyright © 2023 Kiwix. All rights reserved.

import Foundation

enum FeatureFlags {
#if DEBUG
    static let wikipediaDarkUserCSS: Bool = true
    static let map: Bool = true
#else
    static let wikipediaDarkUserCSS: Bool = false
    static let map: Bool = false
#endif
    /// Display or not the Library items in the side menu, such as Opened, Categories, Downloads, New
    static let hasLibrary: Bool = Config.value(for: .hasLibrary) ?? true
}
