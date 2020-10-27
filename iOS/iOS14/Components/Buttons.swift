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
struct BarButtonModifier: ViewModifier {
    @Binding var isPushed: Bool
    let imagePadding: CGFloat
    
    init(isPushed: Binding<Bool>? = nil, imagePadding: CGFloat = 10) {
        self._isPushed = isPushed ?? .constant(false)
        self.imagePadding = imagePadding
    }
    
    private func image(_ content: Content) -> some View {
        content.font(Font.body.weight(.regular)).imageScale(.large).padding(imagePadding)
    }
    
    func body(content: Content) -> some View {
        return ZStack {
            if isPushed {
                Color(.systemBlue)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                image(content).foregroundColor(Color(.systemBackground))
            } else {
                image(content)
            }
        }
    }
}

@available(iOS 14.0, *)
struct SearchCancelButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        Button {
            sceneViewModel.searchBar.delegate?.searchBarCancelButtonClicked?(sceneViewModel.searchBar)
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
        .modifier(BarButtonModifier())
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
        .modifier(BarButtonModifier())
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
        .modifier(BarButtonModifier(imagePadding: 5))
    }
}

@available(iOS 14.0, *)
struct RecentArticlesButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "clock.arrow.circlepath")
        }
        .modifier(BarButtonModifier(imagePadding: 5))
    }
}

@available(iOS 14.0, *)
struct RandomArticlesButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "die.face.5")
        }
        .modifier(BarButtonModifier(imagePadding: 5))
    }
}

@available(iOS 14.0, *)
struct TableOfContentsButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "list.bullet")
        }
        .modifier(BarButtonModifier(imagePadding: 5))
    }
}

@available(iOS 14.0, *)
struct MapButton: View {
    var body: some View {
        Button {
            
        } label: {
            Image(systemName: "map")
        }
        .modifier(BarButtonModifier(imagePadding: 5))
    }
}

@available(iOS 14.0, *)
struct HomeButton: View {
    @EnvironmentObject var sceneViewModel: SceneViewModel

    var body: some View {
        let isPushed = Binding<Bool>(
            get: { sceneViewModel.contentDisplayMode == .homeView },
            set: { _ in }
        )
        Button {
            sceneViewModel.houseButtonTapped()
        } label: {
            Image(systemName: "house")
        }
        .modifier(BarButtonModifier(isPushed: isPushed, imagePadding: 5))
        .disabled(sceneViewModel.currentArticleURL == nil)
    }
}
