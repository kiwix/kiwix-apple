//
//  MapController.swift
//  iOS
//
//  Created by Chris Li on 11/30/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import MapKit

@available(iOS 13.0, *)
class MapController: UIViewController {
    private let mapView = MKMapView()
    let locationManager = CLLocationManager()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Map"
        tabBarItem = UITabBarItem(
            title: "Map", image: UIImage(systemName: "map"), selectedImage: UIImage(systemName: "map.fill"))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "location"), style: .plain, target: self, action: #selector(centerMap))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Check for Location Services
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.requestWhenInUseAuthorization()
        }

        
    }
    
    override func loadView() {
        view = mapView
    }
    
    @objc func centerMap() {
        //Zoom to user location
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
            mapView.setRegion(viewRegion, animated: false)
        }

        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
    }
}
