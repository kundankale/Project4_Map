//
//  MapViewController.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 08/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//

import Foundation
import UIKit
import MapKit

@available(iOS 10.0, *)
class MapViewController: StudentInfoViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
    
    override func studentLocationLoaded(error: Errors?) {
        if error != nil {
            showAlertDialog(title: "OnTheMyMap", message: (error)!.rawValue, dismissHandler: nil)
            return
        }
        
        // Set annotations on map
        var annotations = [MKPointAnnotation]()
        for studentLocation in Cache.shared.studentLocations {
            annotations.append(studentLocation.annotation())
        }
        self.mapView.addAnnotations(annotations)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }  else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            openUrl(url: view.annotation?.subtitle!)
        }
    }
}

