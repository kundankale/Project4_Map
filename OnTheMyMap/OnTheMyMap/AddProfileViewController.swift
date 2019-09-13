//
//  AddProfileViewController.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 06/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//

import UIKit
import MapKit

@available(iOS 10.0, *)
class AddProfileViewController: UIViewController, UITextFieldDelegate {
    
    var locationString: String?
    var lat: Double?
    var lng: Double?
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var txtFieldProfileLinkInput: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnAddPin: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let userInfo = Cache.shared.userInfo
        lblName.text = "\(userInfo?.firstName ?? "") \(userInfo?.lastName ?? "")"
        lblLocation.text = locationString
        
        txtFieldProfileLinkInput.delegate = self
        
        btnAddPin.isEnabled = false
        
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = lat!
        annotation.coordinate.longitude = lng!
        mapView.addAnnotation(annotation)
        mapView.centerCoordinate = annotation.coordinate
        mapView.region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3))
    }
    
    @IBAction func addPinButtonClick(_ sender: Any) {
        let mediaUrl = txtFieldProfileLinkInput.text
    ParseHandler.shared.postStudentLocation(locationString: locationString!, mediaUrl: mediaUrl!, lat: lat!, lng: lng!, onComplete: {error in
            DispatchQueue.main.async {
                if error != nil {
                    self.showAlertDialog(title: "OnTheMyMap", message: (error)!.rawValue, dismissHandler: nil)
                    return
                }
                self.showAlertDialog(title: "OnTheMyMap", message: "Students can see you.", dismissHandler: { _ in
                    self.navigationController?.popToRootViewController(animated: true)
                })
            }
        })
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        btnAddPin.isEnabled = ((txtFieldProfileLinkInput.text?.count ?? 0) > 0)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        btnAddPin.isEnabled = ((txtFieldProfileLinkInput.text?.count ?? 0) > 0)
        txtFieldProfileLinkInput.resignFirstResponder()
        return true
    }
}
