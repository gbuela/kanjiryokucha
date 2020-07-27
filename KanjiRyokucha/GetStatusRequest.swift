//
//  GetStatusRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/3/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation

struct GetStatusModel: Decodable {
    let newCards: Int
    let expiredCards: Int
    let failedCards: Int
    let learnedCards: Int
    
    enum CodingKeys: String, CodingKey {
        case newCards = "new_cards"
        case expiredCards = "due_cards"
        case failedCards = "relearn_cards"
        case learnedCards = "learned_cards"
    }
}

struct GetStatusRequest: KoohiiRequest {
    typealias ModelType = GetStatusModel
    typealias InputType = NoInput
    let apiMethod = "srs/info"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
}
