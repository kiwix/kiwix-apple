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

struct ZimFilters: ToolbarContent {
    
    @Binding var sortBy: ZIMsSortBy
    @Binding var showBy: ZIMsShowBy
    
    var body: some ToolbarContent {
        #if os(iOS)
        ToolbarItemGroup {
            sortByName()
            sortByFileSize()
            showFilter()
        } label: {
            Label("", systemImage: showBy.filterMenuSystemIcon)
        }
        #else
        ToolbarItemGroup(placement: .secondaryAction) {
            sortByName()
                .buttonStyle(.borderless)
                .padding(.horizontal)
            sortByFileSize()
                .buttonStyle(.borderless)
                .padding(.horizontal)
            showFilter()
                .buttonStyle(.borderless)
                .padding(.horizontal)
        }
        #endif
    }
    
    @ViewBuilder
    private func sortByName() -> some View {
        Button {
            sortBy = sortBy.toggleByName()
        } label: {
            if sortBy.isByName {
                Label(ZIMsSortBy.byNameTitle, systemImage: sortBy.systemIcon)
                    .labelStyle(.titleAndIcon)
            } else {
                Text(ZIMsSortBy.byNameTitle)
            }
        }
    }
    
    @ViewBuilder
    private func sortByFileSize() -> some View {
        Button {
            sortBy = sortBy.toggleBySize()
        } label: {
            if sortBy.isBySize {
                Label(ZIMsSortBy.bySizeTitle, systemImage: sortBy.systemIcon)
                    .labelStyle(.titleAndIcon)
            } else {
                Text(ZIMsSortBy.bySizeTitle)
            }
        }
    }
    
    @ViewBuilder
    private func showFilter() -> some View {
        Button {
            showBy = showBy.toggleNext()
        } label: {
            Label(showBy.title, systemImage: showBy.systemIcon)
                .labelStyle(.titleAndIcon)
        }
    }
}
