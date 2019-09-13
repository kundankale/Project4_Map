//
//  ViewController.swift
//  OnTheMyMap
//
//  Created by Kundan Kale on 06/09/19.
//  Copyright © 2019 Kundan Kale. All rights reserved.
//

import UIKit
import Foundation

class LoginPageViewController: UIViewController {
    
    @IBOutlet var launchLogo: UIImageView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var indicatorView: UIActivityIndicatorView!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var loginButton: UIButton!
    
    enum ViewState {
        case NORMAL
        case LOADING
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        setViewState(ViewState.LOADING)
        // The initial view is set for auto login
        // Start auto login
        Authentication.shared.tryAutoLogin({error in
            DispatchQueue.main.async(execute: {
                self.onLoginResult(error: error)
            })
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    @IBAction func onLoginClicked(_ sender: Any) {
        startLogin()
    }
    
    func startLogin() {
        let email = emailTextField.text!
        let password = passwordTextField.text!
        
        if email.isEmpty || password.isEmpty {
            showAlertDialog(title: "OnTheMyMap", message: "Please enter valid email and password to continue.", dismissHandler: nil)
            return
        }
        
        setViewState(ViewState.LOADING)
        Authentication.shared.makeLoginCall(email: email, password: password, onComplete: {error in
            DispatchQueue.main.async(execute: {
                self.onLoginResult(error: error)
            })
        })
    }
    
    func onLoginResult(error: Errors?) {
        setViewState(ViewState.NORMAL)
        
        if error == nil {
            onLoginSuccess()
            return
        }
        
        // If credentials are expired, just show login view to re-authenticate
        if error! == Errors.CredentialExpiredError {
            return
        }
        
        showAlertDialog(title: "OnTheMyMap", message: (error)!.rawValue, dismissHandler: nil)
    }
    
    func onLoginSuccess() {
        // Start Home Screen
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController") {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    func setViewState(_ viewState: ViewState) {
        switch viewState {
        case ViewState.NORMAL:
            emailTextField.isEnabled = true
            passwordTextField.isEnabled = true
            loginButton.isEnabled = true
            indicatorView.stopAnimating()
            indicatorView.isHidden = true
            break
        case ViewState.LOADING:
            emailTextField.isEnabled = false
            passwordTextField.isEnabled = false
            loginButton.isEnabled = false
            indicatorView.isHidden = false
            indicatorView.startAnimating()
            break
        }
    }


}


// ****** MAking extenstion for to separate out TextFieldDelegate
extension LoginPageViewController : UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == emailTextField) {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            startLogin()
        }
        return true
    }
    
    // MARK: Keyboard Methods
    
    func subscribeToKeyboardNotifications() {
        // Use UIKeyboard WillChangeFrame instead of WillShow for supporting multiple keyboards
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        // Removes all notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillChange(_ notification:Notification) {
        // Bottom Y point of the stack view
        let safeBottom = self.stackView.frame.maxY + 16
        
        // Top Y point of keyboard
        let keyboardTop = self.view.frame.height - getKeyboardHeight(notification)
        
        let offset = safeBottom - keyboardTop
        
        // If the stackview is completely visible, no need to shift view
        if (offset <= 0) {
            return
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame.origin.y = 0
            self.view.frame.origin.y -= offset
        })
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        // Reset the view to it's original position
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame.origin.y = 0
        })
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
}

extension UIViewController {
    
    func showAlertDialog(title: String, message: String, dismissHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: dismissHandler))
        self.present(alert, animated: true)
    }
}

