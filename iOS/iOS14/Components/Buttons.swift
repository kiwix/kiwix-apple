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
            sceneViewModel.goBack()
        } label: {
            Image(systemName: "chevron.left")
        }
        .disabled(!sceneViewModel.canGoBack || sceneViewModel.contentDisplayMode != .webView)
    }
}

@available(iOS 14.0, *)
struct GoForwardButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        Button {
            sceneViewModel.goForward()
        } label: {
            Image(systemName: "chevron.right")
        }
        .disabled(!sceneViewModel.canGoForward || sceneViewModel.contentDisplayMode != .webView)
    }
}

@available(iOS 14.0, *)
struct BookmarkArtilesButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "bookmark")
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
struct RandomArticlesButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "die.face.5")
        }
    }
}

@available(iOS 14.0, *)
struct TableOfContentsButton: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var sceneViewModel: SceneViewModel
    @State private var isPresented: Bool = false
    
    var body: some View {
        button.sheet(isPresented: self.$isPresented) {
            OutlineView(outlineItems: sceneViewModel.currentArticleOutlineItems, isPresented: $isPresented)
        }
    }
    
    var button: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "list.bullet")
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
                if sceneViewModel.contentDisplayMode == .homeView {
                    Color(sceneViewModel.currentArticleURL == nil ? .systemGray3 : .systemBlue)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                Image(systemName: "house").imageScale(.large).padding(5)
                    .foregroundColor(sceneViewModel.contentDisplayMode == .homeView ? Color(.systemBackground) : nil)
            }
        }.disabled(sceneViewModel.currentArticleURL == nil)
    }
}
