//
//  LoginRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/3/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation

struct NoModel: Decodable {
}

struct LoginRequest: KoohiiRequest {
    typealias ModelType = NoModel
    typealias InputType = NoInput
    
    let apiMethod: String
    let useEndpoint = false
    let sendApiKey = false
    let method = RequestMethod.post
    let contentType = ContentType.form
    
    let username: String
    let password: String
    let usernameFieldName: String
    let passwordFieldName: String
    let extraParams: ParamSet
    let submitParams: ParamSet
    
    init(username: String,
         password: String,
         usernameFieldName: String = "username",
         passwordFieldName: String = "password",
         extraParams: ParamSet = [:],
         submitParams: ParamSet = [:],
         apiMethod: String = "/login") {
        self.username = username
        self.password = password
        self.usernameFieldName = usernameFieldName
        self.passwordFieldName = passwordFieldName
        self.extraParams = extraParams
        self.submitParams = submitParams
        self.apiMethod = apiMethod
    }
    
    var postParams: ParamSet {
        var params = [ usernameFieldName : username,
                       passwordFieldName : password,
                       "referer" : "@homepage",
                       "commit" : "Login" ]
        extraParams.forEach { key, value in
            params[key] = value
        }
        submitParams.forEach { key, value in
            params[key] = value
        }
        return params
    }
    var headers: ParamSet {
        return [ "Host" : backendDomain,
                 "Origin" : backendHost,
                 "Referer" : backendHost + apiMethod ]
    }
}
