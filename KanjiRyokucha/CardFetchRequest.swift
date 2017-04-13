//
//  CardFetchRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/24/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
import Gloss

internal let cardDataKey = "card_data"

struct CardModel: Decodable {
    let keyword: String
    let strokeCount: Int
    let frameNum: Int
    let cardId: Int
    
    init?(json: JSON) {
        guard let _keyword: String = "keyword" <~~ json,
            let _strokeCount: Int = "strokecount" <~~ json,
            let _frameNum: Int = "framenum" <~~ json,
            let _cardId: Int = "id" <~~ json else {
                return nil
        }
        keyword = _keyword
        strokeCount = _strokeCount
        frameNum = _frameNum
        cardId = _cardId
    }
}

struct CardDataModel: Decodable {
    let cards: [CardModel]
    
    init?(json: JSON) {
        guard let items:[CardModel] = cardDataKey <~~ json else {
            return nil
        }
        cards = items
    }
    
    static func nullObject() -> CardDataModel {
        return CardDataModel(json: [cardDataKey:[]])!
    }
}

struct CardFetchRequest: KoohiiRequest {
    let qsParams: ParamSet
    let cardFetchLimit = 10
    
    typealias ModelType = CardDataModel
    let apiMethod = "review/fetch"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
    var querystringParams: ParamSet {
        return qsParams
    }
    
    init(cardIds: [Int]) {
        let ids = cardIds.prefix(cardFetchLimit).map { String($0) }
        let items = ids.joined(separator: ",")
        qsParams = [ "items": items ]
        
        if Global.isGuest() {
            let guestCards = cardIds.map { id -> String in
                let card = GuestData.cardModel(forId: id)
                return "{\"keyword\":\"\(card.keyword)\",\"strokecount\":\(card.strokeCount), \"framenum\":\(card.frameNum),\"id\":\(id)}"
            }
            
            let guestCardsString = guestCards.joined(separator: ",")
            
            self.guestResult = "{\"stat\":\"ok\",\"card_data\":[\(guestCardsString)],\"dbg_generation_time\":\"562\"}"
        } else {
            self.guestResult = nil
        }
    }
    
    let guestResult: String?
}
