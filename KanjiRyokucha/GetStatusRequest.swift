//
//  GetStatusRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/3/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
import Gloss

struct GetStatusModel: Decodable {
    let newCards: Int
    let expiredCards: Int
    let failedCards: Int
    let learnedCards: Int
    
    init?(json: JSON) {
        guard let new: Int = "new_cards" <~~ json,
            let expired: Int = "due_cards" <~~ json,
            let failed: Int = "relearn_cards" <~~ json,
            let learnedCards: Int = "learned_cards" <~~ json else {
                return nil
        }
        self.newCards = new
        self.expiredCards = expired
        self.failedCards = failed
        self.learnedCards = learnedCards
    }
}

struct GetStatusRequest: KoohiiRequest {
    typealias ModelType = GetStatusModel
    let apiMethod = "srs/info"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
}
