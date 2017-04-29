//
//  AccountInfoRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/29/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

struct AccountInfoModel: Decodable {
    let username: String
    // ignoring other response fields... we only use this api for session check
    
    init?(json: JSON) {
        guard let username: String = "username" <~~ json else {
            return nil
        }
        self.username = username
    }
}

struct AccountInfoRequest: KoohiiRequest {
    typealias ModelType = AccountInfoModel
    let apiMethod = "account/info"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
    
    let guestResult: String? = {
        if Global.isGuest() {
            return "{\"stat\":\"ok\",\"username\":\"guest\"}"
        } else {
            return nil
        }
    }()
}
