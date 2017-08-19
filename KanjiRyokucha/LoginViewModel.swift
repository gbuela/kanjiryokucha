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

enum LoginState {
    case loggingIn
    case loggedIn
    case failure(String)
    
    func isLoggingIn() -> Bool {
        guard case .loggingIn = self else { return false }
        return true
    }
    
    func isFailure() -> Bool {
        guard case .failure(_) = self else { return false }
        return true
   }
}

struct LoginViewModel : BackendAccess {
    let state: MutableProperty<LoginState> = MutableProperty(.loggingIn)
    let credentialsRequired: MutableProperty<Bool> = MutableProperty(false)
    
    let sendLoginNotification: Bool
 
    func autologin() {
        let defaults = UserDefaults()
        if let username = defaults.object(forKey: usernameKey) as? String,
            let password = defaults.object(forKey: passwordKey) as? String {
            attemptLogin(withUsername: username, password: password)
        } else {
            credentialsRequired.value = true
        }
    }
    
    func attemptLogin(withUsername username: String, password: String) {
        state.value = .loggingIn
        
        guard username != guestUsername else {
            loginHandler(success: true, username: username)
            return
        }
        
        callLogin(username: username, password: password, handler: loginHandler)
    }
    
    func loginHandler(success: Bool, username: String?) {
        if success,
            let username = username {
            setDefaultRealmForUser(username: username)
            if sendLoginNotification {
                NotificationCenter.default.post(name: NSNotification.Name(sessionStartedNotification), object: username)
            }
        }
    }
    
    private func setDefaultRealmForUser(username: String) {
        var config = Realm.ConfigurationWithMigration()
        
        config.fileURL = config.fileURL!.deletingLastPathComponent()
            .appendingPathComponent("\(username).realm")
        
        Realm.Configuration.defaultConfiguration = config
        Global.username = username
        
        if Global.isGuest() {
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }
        }
    }
    
    private func callLogin(username:String, password:String, handler:@escaping ((Bool,String?) -> Void)) {
        
        let loginRq = LoginRequest(username: username, password: password)
        
        if let sp = loginRq.requestProducer()?.observe(on: UIScheduler()) {
            
            sp.startWithResult { (result: Result<Response, FetchError>) in
                if let response = result.value {
                    if response.statusCode == httpStatusMovedTemp,
                        let location = response.headers[HeaderKeys.location] as? String,
                        location.hasPrefix(self.backendHost) {
                        if let cookie = response.headers[HeaderKeys.setCookie] as? String {
                            Response.latestCookies = [ cookie ]
                        }
                        self.state.value = .loggedIn
                        handler(true, username)
                    } else {
                        self.state.value = .failure("Could not login 🤔")
                        handler(false, nil)
                    }
                } else {
                    if let fe = result.error {
                        self.state.value = .failure("\(fe.errorText())  🔥")
                    } else {
                        self.state.value = .failure("Apparently we're offline ☹️")
                    }
                    handler(false, nil)
                }
            }
        }
    }
}

