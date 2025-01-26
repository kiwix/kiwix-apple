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

struct ZimFileRow: View {
    @ObservedObject var zimFile: ZimFile

    init(_ zimFile: ZimFile) {
        self.zimFile = zimFile
    }

    var body: some View {
        HStack {
            Favicon(
                category: Category(rawValue: zimFile.category) ?? .other,
                imageData: zimFile.faviconData,
                imageURL: zimFile.faviconURL
            ).frame(height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(zimFile.name).lineLimit(1)
                Text([
                    Formatter.dateShort.string(from: zimFile.created),
                    Formatter.size.string(fromByteCount: zimFile.size),
                    {
                        "\(zimFile.articleCount.formatted(.number.notation(.compactName))) " +
                        LocalString.zim_file_cell_article_count_suffix
                    }()
                ].joined(separator: ", ")).font(.caption)
            }
            Spacer()
            if zimFile.isMissing { ZimFileMissingIndicator() }
        }
    }
}

struct ZimFileRow_Previews: PreviewProvider {
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
        zimFile.name = "Wikipedia Zim File Name"
        zimFile.persistentID = ""
        zimFile.size = 1000000000

        return zimFile
    }()

    static var previews: some View {
        Group {
            ZimFileRow(ZimFileRow_Previews.zimFile)
                .preferredColorScheme(.light)
                .padding()
                .previewLayout(.sizeThatFits)
            ZimFileRow(ZimFileRow_Previews.zimFile)
                .preferredColorScheme(.dark)
                .padding()
                .previewLayout(.sizeThatFits)
            ZimFileRow(ZimFileRow_Previews.zimFile)
                .preferredColorScheme(.light)
                .padding()
                .previewLayout(.sizeThatFits)
            ZimFileRow(ZimFileRow_Previews.zimFile)
                .preferredColorScheme(.dark)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
