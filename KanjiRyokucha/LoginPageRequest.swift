//
//  LoginPageRequest.swift
//  KanjiRyokucha
//
//  Created by Codex on 2025-02-14.
//

import Foundation

struct LoginPageRequest: KoohiiRequest {
    typealias ModelType = NoModel
    typealias InputType = NoInput

    let apiMethod = "/login"
    let useEndpoint = false
    let sendApiKey = false
    let method = RequestMethod.get
    let contentType = ContentType.form
}
