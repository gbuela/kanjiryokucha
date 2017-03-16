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
import SafariServices

let usernameKey = "username"
let passwordKey = "passwordKey"
let httpStatusMovedTemp = 302

class CredentialsViewController: UIViewController, UITextFieldDelegate {
    
    private class func notEmpty(string: String?) -> Bool {
        return string != nil && string != ""
    }
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var loginContainer: UIView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var storeSwitch: UISwitch!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    let loginController = LoginController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        versionLabel.text = versionNumber
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(userTappedBackground))
        view.addGestureRecognizer(tap)
        
        loginButton.isEnabled = false
        
        loginButton.reactive.isEnabled <~
            usernameField.reactive.continuousTextValues.map(CredentialsViewController.notEmpty).combineLatest(with: passwordField.reactive.continuousTextValues.map(CredentialsViewController.notEmpty)).map { $0 && $1 }
    }
    
    func enteredCredentials(username: String, password: String) {
        loginController.callLogin(username: username, password: password, handler: loginController.loginHandler)
    }
    
    @IBAction func userTappedBackground() {
        view.endEditing(true)
    }
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        attemptLogin()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1;
        
        if let nextView = textField.superview?.viewWithTag(nextTag) {
            nextView.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            attemptLogin()
        }
        
        return false
    }
    
    private func attemptLogin() {
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
    
    @IBAction func signupPressed(_ sender: AnyObject) {
        guard let url = URL(string: "http://kanji.koohii.com/account/create") else { return }
        let safariVC = SFSafariViewController(url: url)
        if #available(iOS 10.0, *) {
            safariVC.preferredBarTintColor = .ryokuchaDark
            safariVC.preferredControlTintColor = .white
        } else {
            safariVC.view.tintColor = .ryokuchaDark
        }
        present(safariVC, animated: true, completion: nil)
    }
}
