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
    @State private var coordinateRegion: MKCoordinateRegion
    private var annotationItems = [CLLocationCoordinate2D]()
    
    init(location: CLLocation?) {
        _coordinateRegion = State(initialValue: MKCoordinateRegion(
            center: location?.coordinate ?? CLLocationCoordinate2D(),
            span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
        ))
        annotationItems = [location?.coordinate ?? CLLocationCoordinate2D()]
    }
    
    var body: some View {
        MapKit.Map(coordinateRegion: $coordinateRegion, annotationItems: annotationItems) { item in
            MapMarker(coordinate: item)
        }
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

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude),\(longitude)"
    }
}
