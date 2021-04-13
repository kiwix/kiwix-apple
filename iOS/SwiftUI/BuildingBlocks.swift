//
//  BuildingBlocks.swift
//  Kiwix
//
//  Created by Chris Li on 10/26/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

@available(iOS 14.0, *)
extension View {
    @ViewBuilder func hidden(_ isHidden: Bool) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
}

@available(iOS 14.0, *)
struct WebView: UIViewRepresentable {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    func makeUIView(context: Context) -> WKWebView { sceneViewModel.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

@available(iOS 13.0, *)
struct DisclosureIndicator: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(Font.footnote.weight(.bold))
            .foregroundColor(Color(.systemFill))
    }
}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
extension List {
    func insetGroupedListStyle() -> some View {
        if #available(iOS 14.0, *) {
            return AnyView(self.listStyle(InsetGroupedListStyle()))
        } else {
            return AnyView(self.listStyle(GroupedListStyle()).environment(\.horizontalSizeClass, .regular))
        }
    }
}

@available(iOS 13.0, *)
struct ZimFileCell: View {
    let zimFile: ZimFile
    
    init(_ zimFile: ZimFile) {
        self.zimFile = zimFile
    }
    
    var body: some View {
        HStack {
            Favicon(data: zimFile.faviconData)
            VStack(alignment: .leading) {
                Text(zimFile.title).lineLimit(1)
                Text(zimFile.fileDescription).lineLimit(1).font(.footnote)
            }.foregroundColor(.primary)
            Spacer()
            DisclosureIndicator()
        }
    }
}

@available(iOS 13.0, *)
struct ZimFileView: View {
    let viewModel: ZimFileView.ViewModel
    let accessory: Accessory
    
    init(_ viewModel: ZimFileView.ViewModel, accessory: Accessory = .none) {
        self.viewModel = viewModel
        self.accessory = accessory
    }
    
    var body: some View {
        HStack {
            Favicon(data: viewModel.faviconData)
            VStack(alignment: .leading) {
                Text(viewModel.title).lineLimit(1)
                Spacer(minLength: 2)
                Text(viewModel.detail).lineLimit(1).font(.footnote)
            }.foregroundColor(.primary)
            Spacer()
            switch accessory {
            case .none:
                EmptyView()
            case .onDevice:
                if viewModel.state == .onDevice {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Image(systemName:"iphone").foregroundColor(.secondary)
                    } else if UIDevice.current.userInterfaceIdiom == .pad {
                        Image(systemName:"ipad").foregroundColor(.secondary)
                    }
                } else {
                    EmptyView()
                }
            }
            DisclosureIndicator()
        }
    }
    
    enum Accessory {
        case none, onDevice
    }
    
    struct ViewModel: Identifiable {
        let id: String
        let title: String
        let detail: String
        let state: ZimFile.State
        let faviconData: Data?
        
        init(_ zimFile: ZimFile) {
            self.id = zimFile.fileID
            self.title = zimFile.title
            self.detail = [
                zimFile.sizeDescription,
                zimFile.creationDateDescription,
                zimFile.articleCountShortDescription,
            ].compactMap({ $0 }).joined(separator: ", ")
            self.state = zimFile.state
            self.faviconData = zimFile.faviconData
        }
    }
}
