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
    case failure(String)
    
    func isLoggingIn() -> Bool {
        switch self {
        case .loggingIn: return true
        default: return false
        }
    }
    
    func isFailure() -> Bool {
        switch self {
        case .failure(_): return true
        default: return false
        }
    }
}

struct LoginViewModel {
    let window = UIWindow(frame: UIScreen.main.bounds)
    let state: MutableProperty<LoginState> = MutableProperty(.loggingIn)
    let credentialsRequired: MutableProperty<Bool> = MutableProperty(false)
    
    func start() {
        autologinOrPrompt()
    }
    
    func autologinOrPrompt() {
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
            NotificationCenter.default.post(name: NSNotification.Name(sessionStartedNotification), object: username)
        }
    }
    
    private func setDefaultRealmForUser(username: String) {
        var config = Realm.Configuration()
        
        config.fileURL = config.fileURL!.deletingLastPathComponent()
            .appendingPathComponent("\(username).realm")
        
        Realm.Configuration.defaultConfiguration = config
        Global.username = username
    }
    
    private func callLogin(username:String, password:String, handler:@escaping ((Bool,String?) -> Void)) {
        
        let loginRq = LoginRequest(username: username, password: password)
        
        if let sp = loginRq.requestProducer()?.observe(on: UIScheduler()) {
            
            sp.startWithResult { (result: Result<Response, FetchError>) in
                if let response = result.value {
                    if response.statusCode == httpStatusMovedTemp,
                        let location = response.headers["Location"] as? String,
                        location.hasPrefix(koohiiHost) {
                        if let cookie = response.headers["Set-Cookie"] as? String {
                            Response.latestCookies = [ cookie ]
                        }
                        handler(true, username)
                    } else {
                        self.state.value = .failure("Could not login 🤔")
                        handler(false, nil)
                    }
                } else {
                    self.state.value = .failure("Apparently we're offline ☹️")
                    handler(false, nil)
                }
            }
        }
    }
}

