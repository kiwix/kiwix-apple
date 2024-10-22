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
import SwiftUI

struct ZimFileCell: View {
    @ObservedObject var zimFile: ZimFile
    @State private var isHovering: Bool = false
    let isLoading: Bool

    let prominent: Prominent

    init(_ zimFile: ZimFile, prominent: Prominent, isLoading: Bool = false) {
        self.zimFile = zimFile
        self.prominent = prominent
        self.isLoading = isLoading
    }

    var body: some View {
        VStack(spacing: 8) {
            switch prominent {
            case .name:
                HStack {
                    Text(
                        zimFile.category == Category.stackExchange.rawValue ?
                        zimFile.name.replacingOccurrences(of: "Stack Exchange", with: "") :
                        zimFile.name
                    ).fontWeight(.semibold).foregroundColor(.primary).lineLimit(1)
                    Spacer()
                    Favicon(
                        category: Category(rawValue: zimFile.category) ?? .other,
                        imageData: zimFile.faviconData,
                        imageURL: zimFile.faviconURL
                    ).frame(height: 20)
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(ZimFileCell.sizeFormatter.string(fromByteCount: zimFile.size))
                            .font(.caption)
                        Text(ZimFileCell.dateFormatter.string(from: zimFile.created))
                            .font(.caption)
                    }.foregroundColor(.secondary)
                    Spacer()
                    if zimFile.isMissing { ZimFileMissingIndicator() }
                    if let flavor = Flavor(rawValue: zimFile.flavor) { FlavorTag(flavor) }
                }
            case .size:
                HStack(alignment: .top) {
                    Text(ZimFileCell.sizeFormatter.string(fromByteCount: zimFile.size))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    if let flavor = Flavor(rawValue: zimFile.flavor) {
                        FlavorTag(flavor)
                    }
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text("\(zimFile.articleCount.formatted(.number.notation(.compactName))) " +
                             "zim_file_cell_article_count_suffix".localized)
                            .font(.caption)
                        Text(ZimFileCell.dateFormatter.string(from: zimFile.created))
                            .font(.caption)
                    }.foregroundColor(.secondary)
                    Spacer()
                    if zimFile.isMissing { ZimFileMissingIndicator() }
                }
            }
        }
        .padding()
        .modifier(CellBackground(isHovering: isHovering || isLoading))
        .modifier(LoadingOverlay(isLoading: isLoading))
        .onHover { self.isHovering = $0 }
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    enum Prominent {
        case name, size
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
            ZimFileCell(ZimFileCell_Previews.zimFile, prominent: .name)
                .preferredColorScheme(.light)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile, 
                        prominent: .name,
                        isLoading: true)
                .preferredColorScheme(.light)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile, prominent: .name)
                .preferredColorScheme(.dark)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile, prominent: .size)
                .preferredColorScheme(.light)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
            ZimFileCell(ZimFileCell_Previews.zimFile, prominent: .size)
                .preferredColorScheme(.dark)
                .padding()
                .frame(width: 300, height: 100)
                .previewLayout(.sizeThatFits)
        }
    }
}
