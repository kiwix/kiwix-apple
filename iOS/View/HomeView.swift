//
//  HomeView.swift
//  iOS
//
//  Created by Chris Li on 1/2/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
fileprivate struct SectionHeaderView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.largeTitle)
            .fontWeight(.bold)
    }
}

@available(iOS 13.0.0, *)
fileprivate struct ArticleView: View {
    let content = """
Land reclamation, usually known as reclamation, and also known as land fill (not to be confused with a landfill), is the process of creating new land from oceans, seas, riverbeds or lake beds. The land reclaimed is known as reclamation ground or land fill.
"""
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Wikipedia")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text("Land reclamation")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                    .frame(height: 5)
                Text(content)
                    .font(.caption)
                    .lineLimit(10)
            }
            .layoutPriority(100)
            Spacer()
        }
    }
}

@available(iOS 13.0, *)
struct HomeView: View {
    var body: some View {
        List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
            ArticleView()
            }.listStyle(GroupedListStyle())
    }
}

@available(iOS 13.0, *)
struct ArticleView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleView().previewLayout(.fixed(width: 400, height: 200))
    }
}

@available(iOS 13.0, *)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
