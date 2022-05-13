//
//  Library.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

#if os(macOS)
struct Library: View {
    @State var selectedTopic: LibraryTopic? = .opened
    
    let topics: [LibraryTopic] = [.opened, .downloads, .new]
    
    var body: some View {
        NavigationView {
            List(selection: $selectedTopic) {
                ForEach(topics, id: \.self) { topic in
                    Label(topic.name, systemImage: topic.iconName)
                }
                Section("Category") {
                    ForEach(Category.allCases.map{ LibraryTopic.category($0) }, id: \.self) { topic in
                        Text(topic.name)
                    }
                }.collapsible(false)
            }
            .frame(minWidth: 200)
            .toolbar { SidebarButton() }
            if let selectedTopic = selectedTopic {
                LibraryContent(topic: selectedTopic)
            }
        }.task {
            try? await Database.shared.refreshZimFileCatalog()
        }
    }
}
#elseif os(iOS)
struct Library: View {
    @Environment(\.presentationMode) var presentationMode
    @SceneStorage("library.selectedTopic") var selectedTopic: LibraryTopic = .opened
    
    let topics: [LibraryTopic] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        TabView(selection: $selectedTopic) {
            ForEach(topics) { topic in
                NavigationView {
                    LibraryContent(topic: topic)
                        .navigationTitle(topic.name)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                }
                .navigationViewStyle(.stack)
                .tag(topic)
                .tabItem { Label(topic.name, image: topic.iconName) }
            }
        }.onAppear {
            Task {
                try? await Database.shared.refreshZimFileCatalog()
            }
        }
    }
}
#endif

extension Library {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let dateFormatterMedium: DateFormatter = {
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
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
    
    static func formattedLargeNumber(from value: Int64) -> String {
        let sign = ((value < 0) ? "-" : "" )
        let abs = Swift.abs(value)
        guard abs >= 1000 else {return "\(sign)\(abs)"}
        let exp = Int(log10(Double(abs)) / log10(1000))
        let units = ["K", "M", "G", "T", "P", "E"]
        let rounded = round(10 * Double(abs) / pow(1000.0,Double(exp))) / 10;
        return "\(sign)\(rounded)\(units[exp-1])"
    }
}

enum LibraryTopic: Hashable, Identifiable, RawRepresentable {
    case opened, new, downloads, categories
    case category(Category)
    
    init?(rawValue: String) {
        let parts = rawValue.split(separator: ".")
        switch parts.first {
        case "new":
            self = .new
        case "downloads":
            self = .downloads
        case "categories":
            self = .categories
        default:
            self = .opened
        }
    }
    
    var rawValue: String {
        switch self {
        case .opened:
            return "opened"
        case .new:
            return "new"
        case .downloads:
            return "downloads"
        case .categories:
            return "categories"
        case .category(let category):
            return "category.\(category.rawValue)"
        }
    }
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .opened:
            return "Opened"
        case .new:
            return "New"
        case .downloads:
            return "Downloads"
        case .categories:
            return "Categories"
        case .category(let category):
            return category.description
        }
    }
    
    var iconName: String {
        switch self {
        case .opened:
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                return "iphone"
            } else {
                return "ipad"
            }
            #elseif os(macOS)
            return "laptopcomputer"
            #endif
        case .new:
            return "newspaper"
        case .downloads:
            return "tray.and.arrow.down"
        case .categories:
            return "books.vertical"
        case .category(_):
            return "book"
        }
    }
    
    var predicate: NSPredicate {
        var predicates = [NSPredicate(format: "languageCode == %@", "en")]
        switch self {
        case .new:
            guard let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) else { break }
            predicates.append(contentsOf: [
                NSPredicate(format: "languageCode == %@", "en"),
                NSPredicate(format: "created > %@", twoWeeksAgo as CVarArg)
            ])
        case .category(let category):
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        default:
            break
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Library().previewDevice("iPhone 13 Pro")
            Library().previewDevice("iPad Pro (11-inch) (3rd generation)")
        }
    }
}

#if os(macOS)
enum UserInterfaceSizeClass {
    case compact
    case regular
}
struct HorizontalSizeClassEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserInterfaceSizeClass = .regular
}
extension EnvironmentValues {
    var horizontalSizeClass: UserInterfaceSizeClass { .regular }
}
#endif

/// Add padding around LazyVGrid, which contains all zim file cells. The padding is adjusted so that the cells align with the search bar.
struct LibraryGridPadding: ViewModifier {
    let width: CGFloat
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.padding(.all)
        #elseif os(iOS)
        content.padding([.horizontal, .bottom], width > 375 ? 20 : 16)
        #endif
    }
}
struct ZimFileCellSelection: ViewModifier {
    @Binding var selected: ZimFile?
    
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onTapGesture {
            selected = zimFile
        }
        #elseif os(iOS)
        NavigationLink {
            if let zimFile = zimFile {
                ZimFileDetail(zimFile: zimFile)
            }
        } label: {
            content
        }
        #endif
    }
}
struct Searchable: ViewModifier {
    @Binding var searchText: String
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.searchable(text: $searchText)
        } else {
            content
        }
    }
}

struct MacAdaptableContent: ViewModifier {
    @Binding var zimFile: ZimFile?
    
    func body(content: Content) -> some View {
        #if os(macOS)
        VStack(spacing: 0) {
            Divider()
            content.safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    if let zimFile = zimFile {
                        ZimFileDetail(zimFile: zimFile)
                    } else {
                        HStack {
                            Spacer()
                            Text("select a zim file")
                            Spacer()
                        }
                    }
                }.frame(width: 275)
            }
        }
        #elseif os(iOS)
        content
        #endif
    }
}

struct ZimFileSelection: ViewModifier {
    @Binding var selected: ZimFile?
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onTapGesture {
            selected = zimFile
        }
        #elseif os(iOS)
        NavigationLink {
            ZimFileDetail(zimFile: zimFile)
        } label: {
            content
        }
        #endif
    }
}

struct ZimFileDetailPanel: ViewModifier {
    let zimFile: ZimFile?
    
    func body(content: Content) -> some View {
        #if os(macOS)
        VStack(spacing: 0) {
            Divider()
            content.safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    if let zimFile = zimFile {
                        ZimFileDetail(zimFile: zimFile)
                    } else {
                        HStack {
                            Spacer()
                            Text("select a zim file")
                            Spacer()
                        }
                    }
                }.frame(width: 275)
            }
        }
        #elseif os(iOS)
        content
        #endif
    }
}
