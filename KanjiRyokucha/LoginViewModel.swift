//
//  LoginController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/4/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import ReactiveSwift
import RealmSwift

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
    }
    
    private func callLogin(username:String, password:String, handler:@escaping ((Bool,String?) -> Void)) {
        
        let loginRq = LoginRequest(username: username, password: password)
        
        if let sp = loginRq.requestProducer()?.observe(on: UIScheduler()) {
            
            sp.startWithResult { (result: Result<Response, FetchError>) in
                switch result {
                case .success(let response):
                    if response.statusCode == httpStatusMovedTemp,
                        let location = response.headers[HeaderKeys.location] as? String,
                        location.hasPrefix(self.backendHost) {
                        if let cookie = response.headers[HeaderKeys.setCookie] as? String {
                            Response.latestCookies = [ cookie ]
                        }
                        handler(true, username)
                        self.state.value = .loggedIn
                    } else {
                        handler(false, nil)
                        self.state.value = .failure("Could not login 🤔")
                    }
                case .failure(let error):
                    handler(false, nil)
                    self.state.value = .failure("\(error.errorText())  🔥")
                }
            }
        }
    }
}

