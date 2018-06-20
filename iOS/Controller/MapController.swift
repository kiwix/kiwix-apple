//
//  MapController.swift
//  iOS
//
//  Created by Chris Li on 5/29/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import MapKit

class MapController: UIViewController {
    let coordinate: CLLocationCoordinate2D
    private let mapView = MKMapView()
    
    init(coordinate: CLLocationCoordinate2D, title: String?) {
        self.coordinate = coordinate
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        
        let region = MKCoordinateRegion(center: self.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: false)
        let annotation = MKPointAnnotation()
        annotation.coordinate = self.coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
}
