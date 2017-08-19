//
//  BackgroundFetcher.swift
//  KanjiRyokucha
//
//  Created by German Buela on 8/17/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import ReactiveSwift

enum BackgroundFetcherResult {
    case notChecked
    case failure
    case success(oldCount: Int, newCount: Int)
}

typealias BackgroundFetcherCompletion = (BackgroundFetcherResult) -> ()

/**
 Goal is to get access to latest due count (saved in Global) and fetch current due
 count from backend. All execution paths should lead to completion closure.
 Prior to fetching status we log in to ensure active session.
 For the purpose of background fetch, we don't care about reasons for failures --
 we either get the values or not.
 We don't care about the UI either. If the user opens the app, it will update its
 UI as usual.
 */
class BackgroundFetcher {
    // we prevent the notification that is meant for presenting credentials vc
    let loginViewModel = LoginViewModel(sendLoginNotification: false)
    var statusAction: Action<Void, Response, FetchError>?
    
    let completion: BackgroundFetcherCompletion
    
    init(completion: @escaping BackgroundFetcherCompletion) {
        self.completion = completion
    }

    func start() {
        loginViewModel.state.react { [weak self] loginState in
            switch loginState {
            case .loggedIn:
                if Database.getGlobal().useNotifications {
                    self?.getCurrentStatus()
                } else {
                    self?.completion(.notChecked)
                }
                break
            case .failure(_):
                self?.completion(.failure)
                break
            default:
                break
            }
        }
        loginViewModel.autologin()
    }
    
    func getCurrentStatus() {
        
        let oldCount = Database.getGlobal().latestDueCount
        
        statusAction = Action<Void, Response, FetchError>(execute: { _ in
            return GetStatusRequest().requestProducer()!
        })
        
        statusAction?.react { [weak self] response in
            if let model = response.model as? GetStatusModel {
                self?.completion(.success(oldCount: oldCount, newCount: model.expiredCards))
            } else {
                self?.completion(.failure)
            }
        }
        statusAction?.errors.react { [weak self] _ in
            self?.completion(.failure)
        }
        
        let delayInSeconds = 3.0
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delayInSeconds) {
            self.statusAction?.apply().start()
        }
    }
}
