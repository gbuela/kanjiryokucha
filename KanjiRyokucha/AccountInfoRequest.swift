//
//  AccountInfoRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/29/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation

struct AccountInfoModel: Decodable {
    let username: String
    // ignoring other response fields... we only use this api for session check
}

struct AccountInfoRequest: KoohiiRequest {
    typealias ModelType = AccountInfoModel
    typealias InputType = NoInput
    let apiMethod = "account/info"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
}
