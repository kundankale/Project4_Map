//
//  InfoTableViewController.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 06/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//


import Foundation
import UIKit

@available(iOS 10.0, *)
class InfoTableViewController: StudentInfoViewController, UITableViewDelegate, UITableViewDataSource {
    
    let TableViewCellReuseIdentifier = "StudentLocationCell"
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func studentLocationLoaded(error: Errors?) {
        if error != nil {
            showAlertDialog(title: "OnTheMyMap", message: (error)!.rawValue, dismissHandler: nil)
            return
        }
        tableView.reloadData()
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return Cache.shared.studentLocations.count
        }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let studentLocation = Cache.shared.studentLocations[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellReuseIdentifier)
            cell?.textLabel?.text = "\(studentLocation.firstName) \(studentLocation.lastName)"
            cell?.detailTextLabel?.text = studentLocation.mapString
            return cell!
        }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
            let studentLocation = Cache.shared.studentLocations[indexPath.row]
            openUrl(url: studentLocation.mediaURL)
            // Deselect the selected row
            tableView.deselectRow(at: indexPath, animated: true)
        }

}

