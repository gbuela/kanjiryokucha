//
//  CredentialsViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/17/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit
import PKHUD
import Result
import ReactiveSwift

let usernameKey = "username"
let passwordKey = "passwordKey"
let httpStatusMovedTemp = 302

class CredentialsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var loginContainer: UIView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var storeSwitch: UISwitch!
    
    let loginController = LoginController()
    
    func enteredCredentials(username: String, password: String) {
        loginController.callLogin(username: username, password: password, handler: loginController.loginHandler)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        guard let username = usernameField.text,
            let password = passwordField.text,
            username != "" &&
                password != ""
            else {
                showAlert("Please enter all fields")
                return
        }
        
        view.endEditing(true)
        
        let defaults = UserDefaults()
        if storeSwitch.isOn {
            defaults.set(username, forKey: usernameKey)
            defaults.set(password, forKey: passwordKey)
        } else {
            defaults.set(nil, forKey: usernameKey)
            defaults.set(nil, forKey: passwordKey)
        }
        
        enteredCredentials(username: username, password: password)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1;
        
        if let nextView = textField.superview?.viewWithTag(nextTag) {
            nextView.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return false
    }
}
