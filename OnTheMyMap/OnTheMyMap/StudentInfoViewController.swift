//
//  StudentInfoViewController.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 07/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//


import Foundation
import UIKit

@available(iOS 10.0, *)
class StudentInfoViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ParseHandler.shared.loadStudentLocations(limit: 100, skip: 0, onComplete: {error in
            DispatchQueue.main.async(execute: {
                self.studentLocationLoaded(error: error)
            })
        })
    }
    
    func studentLocationLoaded(error: Errors?) {
        // To be overridden
    }
    
    func openUrl(url: String?) {
        if let url = URL(string: url!) {
            let app = UIApplication.shared
            app.open(url, options: [:], completionHandler: nil)
        } else {
            showAlertDialog(title: "OnTheMyMap", message: "The media URL provided is not a valid URL.", dismissHandler: nil)
        }
    }
}

