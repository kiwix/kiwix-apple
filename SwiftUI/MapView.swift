//
//  MapView.swift
//  Kiwix
//
//  Created by Chris Li on 8/1/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import MapKit
import SwiftUI

struct MapView: View {
    @State var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.361145, longitude: -71.057083),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    var body: some View {
        Map(coordinateRegion: $coordinateRegion)
            .navigationTitle("Map")
            .ignoresSafeArea(.all)
    }
}
