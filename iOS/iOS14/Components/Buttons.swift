//
//  Buttons.swift
//  Kiwix
//
//  Created by Chris Li on 10/24/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct RoundedRectButton: View {
    let title: String
    let iconSystemName: String
    let backgroundColor: Color
    var action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            Label(
                title: { Text(title).fontWeight(.semibold) },
                icon: { Image(systemName: iconSystemName) }
            )
            .font(.subheadline)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .foregroundColor(.white)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

@available(iOS 14.0, *)
struct SearchCancelButton: View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    
    var body: some View {
        Button {
            searchViewModel.cancelSearch()
        } label: {
            Text("Cancel").fontWeight(.regular)
        }
    }
}

@available(iOS 14.0, *)
struct GoBackButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        Button {
            sceneViewModel.webView.goBack()
        } label: {
            Image(systemName: "chevron.left")
        }
        .disabled(!sceneViewModel.canGoBack || sceneViewModel.contentDisplayMode != .web)
    }
}

@available(iOS 14.0, *)
struct GoForwardButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        Button {
            sceneViewModel.webView.goForward()
        } label: {
            Image(systemName: "chevron.right")
        }
        .disabled(!sceneViewModel.canGoForward || sceneViewModel.contentDisplayMode != .web)
    }
}

@available(iOS 14.0, *)
struct BookmarksButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        Button {
            if sceneViewModel.isSidebarVisible, sceneViewModel.sidebarContentMode == .bookmark {
                sceneViewModel.hideSidebar()
            } else {
                sceneViewModel.showSidebar(content: .bookmark)
            }
        } label: {
            Image(systemName: "bookmark")
        }
    }
}

@available(iOS 14.0, *)
struct OutlineButton: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @Binding var isSheetPresented: Bool
    
    var body: some View {
        Button {
            if horizontalSizeClass == .compact {
                isSheetPresented = true
            } else if sceneViewModel.isSidebarVisible, sceneViewModel.sidebarContentMode == .outline {
                sceneViewModel.hideSidebar()
            } else {
                sceneViewModel.showSidebar(content: .outline)
            }
        } label: {
            Image(systemName: "list.bullet")
        }
    }
}

@available(iOS 14.0, *)
struct RandomArticlesButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "die.face.5")
        }
    }
}

@available(iOS 14.0, *)
struct RecentArticlesButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "clock.arrow.circlepath")
        }
    }
}

@available(iOS 14.0, *)
struct MapButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "map")
        }
    }
}

@available(iOS 14.0, *)
struct HomeButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        Button {
            sceneViewModel.houseButtonTapped()
        } label: {
            ZStack {
                if sceneViewModel.contentDisplayMode == .home {
                    Color(sceneViewModel.currentArticleURL == nil ? .systemGray3 : .systemBlue)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                Image(systemName: "house").imageScale(.large).padding(5)
                    .foregroundColor(sceneViewModel.contentDisplayMode == .home ? Color(.systemBackground) : nil)
            }
        }.disabled(sceneViewModel.currentArticleURL == nil)
    }
}
