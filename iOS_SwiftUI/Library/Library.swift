//
//  Library.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

#if os(macOS)
enum UserInterfaceSizeClass {
    case compact
    case regular
}

struct HorizontalSizeClassEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserInterfaceSizeClass = .regular
}
struct VerticalSizeClassEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserInterfaceSizeClass = .regular
}

extension EnvironmentValues {
    var horizontalSizeClass: UserInterfaceSizeClass {
        get { .regular }
    }
    var verticalSizeClass: UserInterfaceSizeClass {
        get { .regular }
    }
}
#endif

struct Library: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            TabView {
                List {
                                        
                }.tabItem {
                    Image(systemName: Topic.opened.iconName)
                    Text(Topic.opened.name)
                }
                List {
                                                        
                }.tabItem {
                    Image(systemName: Topic.categories.iconName)
                    Text(Topic.categories.name)
                }
                List {
                                                        
                }.tabItem {
                    Image(systemName: Topic.downloads.iconName)
                    Text(Topic.downloads.name)
                }
                List {
                                                        
                }.tabItem {
                    Image(systemName: Topic.new.iconName)
                    Text(Topic.new.name)
                }
            }
        } else {
            NavigationView {
                List {
                    ForEach([Topic.opened, Topic.downloads, Topic.new]) { topic in
                        Label(topic.name, systemImage: topic.iconName)
                    }
                }.navigationTitle("Library")
                Text("content")
            }
        }
    }
    
    enum Topic: Hashable, Identifiable {
        case opened, new, downloads, categories
        case category(Category)
        
        var id: String { name }
        
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
