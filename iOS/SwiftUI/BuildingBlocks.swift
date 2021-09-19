//
//  BuildingBlocks.swift
//  Kiwix
//
//  Created by Chris Li on 10/26/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

struct ActionCell: View {
    let title: String
    let isDestructive: Bool
    let alignment: HorizontalAlignment
    let action: (() -> Void)
    
    init(title: String,
         isDestructive: Bool = false,
         alignment: HorizontalAlignment = .center,
         action: @escaping (() -> Void) = {}
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.alignment = alignment
        self.action = action
    }
    
    var body: some View {
        Button(action: action, label: {
            HStack {
                if alignment != .leading { Spacer() }
                Text(title)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : nil)
                if alignment != .trailing { Spacer() }
            }
        })
    }
}

@available(iOS 14.0, *)
struct RoundedRectButton: View {
    let title: String
    let iconSystemName: String
    let backgroundColor: Color
    var isCompact = true
    var action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            content
            .font(.subheadline)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(backgroundColor))
        }
    }
    
    var content: some View {
        if isCompact {
            return AnyView(label)
        } else {
            return AnyView(HStack {
                Spacer()
                label
                Spacer()
            })
        }
    }
    
    var label: some View {
        Label(
            title: { Text(title).fontWeight(.semibold) },
            icon: { Image(systemName: iconSystemName) }
        )
    }
}

struct DisclosureIndicator: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(Font.footnote.weight(.bold))
            .foregroundColor(Color(.systemFill))
    }
}

struct Favicon: View {
    private let image: Image
    private let outline = RoundedRectangle(cornerRadius: 4, style: .continuous)
    
    init(data: Data?) {
        if let data = data, let image = UIImage(data: data) {
            self.image = Image(uiImage: image)
        } else {
            self.image = Image("GenericZimFile")
        }
    }
    
    init(uiImage: UIImage) {
        self.image = Image(uiImage: uiImage)
    }
    
    var body: some View {
        image
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .background(Color(.white))
            .clipShape(outline)
            .overlay(outline.stroke(Color(.white).opacity(0.9), lineWidth: 1))
    }
}

struct InfoView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let imageSystemName: String
    let title: String
    let help: String
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer(minLength: geometry.size.height * 0.3)
                if verticalSizeClass == .regular {
                    VStack {
                        makeImage(geometry)
                        text
                    }
                } else {
                    HStack {
                        makeImage(geometry)
                        text
                    }
                }
                Spacer()
                Spacer()
            }.frame(width: geometry.size.width)
        }
    }
    
    private func makeImage(_ geometry: GeometryProxy) -> some View {
        GeometryReader { geometry in
            ZStack {
                Image(systemName: imageSystemName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(geometry.size.height * 0.25)
                    .foregroundColor(.secondary)
                Circle().foregroundColor(.secondary).opacity(0.2)
            }
        }
        .frame(
            width: max(60, min(geometry.size.height * 0.2, geometry.size.width * 0.2, 100)),
            height: max(60, min(geometry.size.height * 0.2, geometry.size.width * 0.2, 100))
        )
    }
    
    var text: some View {
        VStack(spacing: 10) {
            Text(title).font(.title).fontWeight(.medium)
            Text(help).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding()
    }
}

extension List {
    func insetGroupedListStyle() -> some View {
        if #available(iOS 14.0, *) {
            return AnyView(self.listStyle(InsetGroupedListStyle()))
        } else {
            return AnyView(self.listStyle(GroupedListStyle()).environment(\.horizontalSizeClass, .regular))
        }
    }
}

struct ListRow: View {
    let title: String
    let detail: String
    let faviconData: Data?
    let accessories: [Accessory]
    
    init(title: String, detail: String, faviconData: Data? = nil, accessories: [Accessory] = [.disclosureIndicator]) {
        self.title = title
        self.detail = detail
        self.faviconData = faviconData
        self.accessories = accessories
    }
    
    var body: some View {
        HStack {
            Favicon(data: faviconData)
            VStack(alignment: .leading) {
                Text(title).lineLimit(1)
                Text(detail).lineLimit(1).font(.footnote)
            }.foregroundColor(.primary)
            Spacer()
            accessory
        }
    }
    
    var accessory: some View {
        ForEach(accessories, id: \.rawValue) { accessory in
            switch accessory {
            case .onDevice:
                if UIDevice.current.userInterfaceIdiom == .phone {
                    Image(systemName:"iphone").foregroundColor(.secondary)
                } else if UIDevice.current.userInterfaceIdiom == .pad {
                    Image(systemName:"ipad").foregroundColor(.secondary)
                }
            case .includedInSearch:
                Image(systemName: "checkmark").foregroundColor(.blue)
            case .disclosureIndicator:
                DisclosureIndicator()
            }
        }
    }
    
    enum Accessory: String {
        case onDevice, includedInSearch, disclosureIndicator
    }
}

struct TitleDetailCell: View {
    let title: String
    let detail: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail).foregroundColor(.secondary)
        }
    }
}

extension View {
    @ViewBuilder func hidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
}

struct ZimFileDownloadDetailView: View {
    static private let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
    private let zimFile: ZimFile
    
    init(_ zimFile: ZimFile) {
        self.zimFile = zimFile
    }
    
    var progress: String {
        [
            ByteCountFormatter.string(fromByteCount: zimFile.downloadTotalBytesWritten, countStyle: .file),
            ZimFileDownloadDetailView.percentFormatter.string(
                from: NSNumber(value: Double(zimFile.downloadTotalBytesWritten) / Double(zimFile.size))
            )
        ].compactMap({ $0 }).joined(separator: " - ")
    }
    
    var body: some View {
        switch zimFile.state {
        case .downloadQueued:
            Text("Queued")
        case .downloadInProgress:
            HStack {
                Text("Downloading...")
                Spacer()
                Text(progress).foregroundColor(.secondary)
            }
        case .downloadPaused:
            HStack {
                Text("Pause")
                Spacer()
                Text(progress).foregroundColor(.secondary)
            }
        case .downloadError:
            Text("Error")
            if let errorDescription = zimFile.downloadErrorDescription {
                Text(errorDescription)
            }
        default:
            EmptyView()
        }
    }
}
