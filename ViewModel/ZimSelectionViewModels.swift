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

@MainActor
final class MultiSelectedZimFilesViewModel: ObservableObject {
    @Published private(set) var selectedZimFiles = Set<ZimFile>()
    
    func toggleMultiSelect(of zimFile: ZimFile) {
        if selectedZimFiles.contains(zimFile) {
            selectedZimFiles.remove(zimFile)
        } else {
            selectedZimFiles.insert(zimFile)
        }
    }
    
    func singleSelect(zimFile: ZimFile) {
        selectedZimFiles = Set([zimFile])
    }
    
    func reset() {
        selectedZimFiles.removeAll()
    }
    
    func isSelected(_ zimFile: ZimFile) -> Bool {
        selectedZimFiles.contains(zimFile)
    }
    
    func intersection(with zimFiles: Set<ZimFile>) {
        selectedZimFiles = selectedZimFiles.intersection(zimFiles)
    }
}

@MainActor
final class SelectedZimFileViewModel: ObservableObject {
    @Published var selectedZimFile: ZimFile?
    
    func reset() {
        selectedZimFile = nil
    }
    
    func isSelected(_ zimFile: ZimFile) -> Bool {
        selectedZimFile == zimFile
    }
}
