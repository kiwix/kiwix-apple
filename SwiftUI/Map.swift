//
//  Map.swift
//  Kiwix
//
//  Created by Chris Li on 8/1/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import MapKit
import SwiftUI

struct Map: View {
    @State var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.361145, longitude: -71.057083),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    var body: some View {
        MapKit.Map(coordinateRegion: $coordinateRegion)
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .modify { view in
                if #available(iOS 16.0, *) {
                    view
                        .toolbarBackground(.visible, for: .navigationBar)
                        .ignoresSafeArea(.all)
                } else {
                    view.ignoresSafeArea(.container, edges: [.horizontal, .bottom])
                }
            }
            
    }
}
