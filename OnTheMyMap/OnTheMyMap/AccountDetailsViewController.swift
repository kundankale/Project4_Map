//
//  AccountDetailsViewController.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 08/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
class AccountDetailsViewController: UIViewController {
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblNickName: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblLogout: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userInfo = Cache.shared.userInfo
        
        lblNickName.text = userInfo?.nickName
        lblName.text = "\(userInfo?.firstName ?? "") \(userInfo?.lastName ?? "")"
        
        DispatchQueue.global(qos: .background).async {
            let image: UIImage
            do {
                let url =  URL(string: "https:" + (userInfo?.imageUrl ?? ""))
                let data = try Data(contentsOf: url!)
                image = UIImage(data: data)!
            } catch {
                image = UIImage(named: "icon_world")!
            }
            
            DispatchQueue.main.async {
                self.imgUser.image = image
            }
        }
    }

    @IBAction func onLogoutClick(_ sender: Any) {
        Authentication.shared.makeLogoutCall({error in
            if error != nil {
                self.showAlertDialog(title: "OnTheMyMap", message: (error?.rawValue)!, dismissHandler: nil)
                return
            }
            
            // Dismiss current view controller
            self.tabBarController?.dismiss(animated: true, completion: nil)
        })
    }
}
