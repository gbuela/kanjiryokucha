//
//  GetStatusRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/3/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
import Gloss

struct GetStatusModel: Gloss.Decodable {
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
    
    let guestResult: String? = {
        if Global.isGuest() {
            let relearnCount = GuestData.failedIds.count + GuestData.studyIds.count
            return "{\"stat\":\"ok\",\"new_cards\":0,\"due_cards\":\(GuestData.dueIds.count),\"relearn_cards\":\(relearnCount),\"learned_cards\":\(GuestData.failedIds.count),\"dbg_generation_time\":\"2161\"}"
        } else {
            return nil
        }
    }()
}
