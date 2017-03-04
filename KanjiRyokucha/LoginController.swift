//
//  LoginController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/4/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import ReactiveSwift
import RealmSwift
import Result
import PKHUD

struct LoginController {
    let window = UIWindow(frame: UIScreen.main.bounds)
    
    func start() {
        window.rootViewController = UIViewController()
        window.rootViewController?.view.backgroundColor = .ryokuchaLight
        window.makeKeyAndVisible()
        
        let defaults = UserDefaults()
        if let username = defaults.object(forKey: usernameKey) as? String,
            let password = defaults.object(forKey: passwordKey) as? String {
            callLogin(username: username, password: password, handler: loginHandler)
        } else {
            promptForCredentials()
        }
    }
    
    func loginHandler(success: Bool, username: String?) {
        if success,
            let username = username {
            setDefaultRealmForUser(username: username)
            NotificationCenter.default.post(name: NSNotification.Name(sessionStartedNotification), object: username)
        }
    }
    
    private func setDefaultRealmForUser(username: String) {
        var config = Realm.Configuration()
        
        config.fileURL = config.fileURL!.deletingLastPathComponent()
            .appendingPathComponent("\(username).realm")
        
        Realm.Configuration.defaultConfiguration = config
    }
    
    func callLogin(username:String, password:String, handler:@escaping ((Bool,String?) -> Void)) {
        
        let loginRq = LoginRequest(username: username, password: password)
        
        if let sp = loginRq.requestProducer()?.observe(on: UIScheduler()) {
            HUD.show(.label("Logging in..."))
            
            sp.startWithResult { (result: Result<Response, FetchError>) in
                if let response = result.value,
                    response.statusCode == httpStatusMovedTemp,
                    let location = response.headers["Location"] as? String,
                    location.hasPrefix(koohiiHost) {
                    HUD.hide()
                    if let cookie = response.headers["Set-Cookie"] as? String {
                        Response.latestCookies = [ cookie ]
                    }
                    handler(true, username)
                } else {
                    HUD.flash(.error, delay:0.5)
                    handler(false, nil)
                }
            }
        }
    }
    
    func promptForCredentials() {
        window.rootViewController = CredentialsViewController()
        window.makeKeyAndVisible()
    }
}

