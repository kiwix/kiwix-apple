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

import CoreData
import Defaults
import SwiftUI

struct ZimFileCell: View {
    @MainActor @ObservedObject var zimFile: ZimFile
    @Default(.zimUpdatesAvailable) private var updates
    @State private var isHovering: Bool = false
    let isLoading: Bool
    let isSelected: Bool
    private let backgroundColoring: (_ isHovering: Bool, _ isSelected: Bool) -> Color

    init(
        _ zimFile: ZimFile,
        isSelected: Bool,
        isLoading: Bool = false,
        backgroundColoring: @escaping (_ isHovering: Bool, _ isSelected: Bool) -> Color = CellBackground.colorFor
    ) {
        self.zimFile = zimFile
        self.isSelected = isSelected
        self.isLoading = isLoading
        self.backgroundColoring = backgroundColoring
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(
                        zimFile.category == Category.stackExchange.rawValue ?
                        zimFile.name.replacingOccurrences(of: "Stack Exchange", with: "") :
                            zimFile.name
                    ).fontWeight(.semibold).foregroundColor(.primary).lineLimit(1)
                }
                Spacer()
                Favicon(
                    category: Category(rawValue: zimFile.category) ?? .other,
                    imageData: zimFile.faviconData,
                    imageURL: zimFile.faviconURL
                ).frame(height: 20)
            }
            Text(zimFile.fileDescription.replacingOccurrences(of: "Stack Exchange ", with: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(LocalString.zim_file_cell_page_count(withArgs: zimFile.pageCountFormatted))
                        Text(LocalString.zim_file_cell_media_count(withArgs: zimFile.mediaCountFormatted))
                    }
                    Text(ZimFileCell.sizeFormatter.string(fromByteCount: zimFile.size))
                }
                .foregroundColor(.secondary)
                .font(.caption)
                if !zimFile.isMissing, let isIntegrityChecked = zimFile.isIntegrityChecked {
                    if isIntegrityChecked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.red)
                    }
                }
                Spacer()
                if zimFile.isMissing { ZimFileMissingIndicator() }
                if let flavor = Flavor(rawValue: zimFile.flavor) { FlavorTag(flavor) }
                if hasUpdate { UpdateAvailableTag() }
            }
        }
        .padding()
        .background(backgroundColoring(isHovering, isSelected))
        .clipShape(CellBackground.clipShapeRectangle)
        .modifier(LoadingOverlay(isLoading: isLoading))
        .onHover { self.isHovering = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : .isButton)
        .accessibilityElement()
        .accessibilityLabel(Self.cellAccessibilityLabel(for: zimFile, hasUpdate: hasUpdate))
        .accessibilityAddTraits(.isButton)
    }

    @MainActor
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    @MainActor
    static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    private var hasUpdate: Bool {
        // only downloaded files can have an update, and checking the (optional) file link first
        // keeps this from reading the fileID of a catalog row the sync has just removed
        guard zimFile.fileURLBookmark != nil else { return false }
        return ZimUpdates.availableUpdate(for: zimFile.fileID, in: updates) != nil
    }

    static func cellAccessibilityLabel(for zimFile: ZimFile, hasUpdate: Bool = false) -> String {
        [zimFile.name,
         zimFile.fileDescription,
         ZimFileCell.sizeFormatter.string(fromByteCount: zimFile.size),
         Flavor(rawValue: zimFile.flavor)?.description,
         LocalString.zim_file_cell_page_count(withArgs: zimFile.pageCountFormatted),
         LocalString.zim_file_cell_media_count(withArgs: zimFile.mediaCountFormatted),
         zimFile.isMissing ? LocalString.zim_file_missing_indicator_help : nil,
         hasUpdate ? LocalString.zim_file_update_tag : nil
        ].compactMap { $0 }.joined(separator: ", ")
    }
}

struct ZimFileCell_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 100
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.fileID = UUID()
        zimFile.flavor = "mini"
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        zimFile.isMissing = true
        zimFile.flavor = "maxi"
        return zimFile
    }()

    static var previews: some View {
        Group {
            ZimFileCell(ZimFileCell_Previews.zimFile, isSelected: false)
                .preferredColorScheme(.light)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile,
                        isSelected: true,
                        isLoading: true)
                .preferredColorScheme(.light)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile, isSelected: false)
                .preferredColorScheme(.dark)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
        }
    }
}
