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

struct LanguageSortControls: View {
    
    @Binding var keyPathCompare: KeyPathComparator<Language>
    
    var body: some View {
        HStack {
            Button {
                didSelectName()
            } label: {
                HStack {
                    Text(LocalString.language_selector_name_title)
                    imageMatchingFor(for: \Language.name)
                }
            }
            Button {
                didSelectCount()
            } label: {
                HStack {
                    Text(LocalString.language_selector_count_table_title)
                    imageMatchingFor(for: \Language.count)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func didSelectName() {
        switch (keyPathCompare.keyPath, keyPathCompare.order) {
        case (\Language.name, .reverse):
            keyPathCompare = KeyPathComparator(\Language.name, order: .forward)
        default:
            keyPathCompare = KeyPathComparator(\Language.name, order: .reverse)
        }
    }
    
    private func didSelectCount() {
        switch (keyPathCompare.keyPath, keyPathCompare.order) {
        case (\Language.count, .reverse):
            keyPathCompare = KeyPathComparator(\Language.count, order: .forward)
        default:
            keyPathCompare = KeyPathComparator(\Language.count, order: .reverse)
        }
    }
    
    @ViewBuilder
    private func imageMatchingFor(for keyPath: PartialKeyPath<Language>) -> some View {
        if keyPathCompare.keyPath == keyPath {
            let imageName = keyPathCompare.order == .forward ? "chevron.down" : "chevron.up"
            Image(systemName: imageName)
        } else {
            EmptyView()
        }
    }
}
