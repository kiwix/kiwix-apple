//
//  OnboardingView.swift
//  Kiwix
//
//  Created by Chris Li on 9/4/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Spacer()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.0001))
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image("Kiwix_logo_v3")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .padding(2)
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.white))
                    Text("Kiwix").font(.largeTitle).fontWeight(.bold)
                    Spacer()
                    
                }
                Divider()
                HStack {
                    Spacer()
                    VStack(spacing: 15) {
                        Text("Existing zim files:").font(.title2).fontWeight(.medium)
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.secondary)
                        FileImportButton()
                    }
                    Spacer()
                    VStack(spacing: 15) {
                        Text("Download zim files:").font(.title2).fontWeight(.medium)
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.secondary)
                        Button("Fetch Online Catalog") {
                            
                        }
                    }
                    Spacer()
                }
            }
            .padding(20)
//            .background { colorScheme == .light ? Color.tertiaryBackground : Color.white.opacity(0.05) }
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            .padding()
            .frame(maxWidth: 600)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .preferredColorScheme(.light)
        OnboardingView()
            .preferredColorScheme(.dark)
    }
}
