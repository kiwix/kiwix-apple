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
    @Environment(\.presentationMode) private var presentationMode
    @SceneStorage("library.selectedTopic") private var selectedTopic: LibraryTopic = .opened
    @StateObject private var viewModel = LibraryViewModel()
    
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
                .tabItem { Label(topic.name, systemImage: topic.iconName) }
            }
        }
        .environmentObject(viewModel)
        .onAppear {
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
