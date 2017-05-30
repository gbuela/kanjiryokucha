//
//  LoginRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/3/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
import Gloss

struct NoModel: Decodable {
    init?(json: JSON) {
        return nil
    }
}

struct LoginRequest: KoohiiRequest {
    typealias ModelType = NoModel
    
    let apiMethod = "/login"
    let useEndpoint = false
    let sendApiKey = false
    let method = RequestMethod.post
    let contentType = ContentType.form
    
    let username: String
    let password: String
    
    var postParams: ParamSet {
        return [ "username" : username,
                 "password" : password,
                 "referer" : "@homepage",
                 "commit" : "Login" ]
    }
    var headers: ParamSet {
        return [ "Host" : backendDomain,
                 "Origin" : backendHost,
                 "Referer" : backendHost + apiMethod ]
    }
    
    let guestResult: String? = nil
}
