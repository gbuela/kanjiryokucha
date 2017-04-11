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
    }
    
    let guestResult: String? = "{\"stat\":\"ok\",\"card_data\":[{\"keyword\":\"six\",\"strokecount\":4,\"framenum\":6,\"id\":20845},{\"keyword\":\"span\",\"strokecount\":6,\"framenum\":32,\"id\":20120},{\"keyword\":\"risk\",\"strokecount\":9,\"framenum\":18,\"id\":20882},{\"keyword\":\"rise up\",\"strokecount\":8,\"framenum\":43,\"id\":26119},{\"keyword\":\"bright\",\"strokecount\":8,\"framenum\":20,\"id\":26126},{\"keyword\":\"measuring box\",\"strokecount\":4,\"framenum\":42,\"id\":21319},{\"keyword\":\"month\",\"strokecount\":4,\"framenum\":13,\"id\":26376},{\"keyword\":\"three\",\"strokecount\":3,\"framenum\":3,\"id\":19977},{\"keyword\":\"round\",\"strokecount\":3,\"framenum\":44,\"id\":20024},{\"keyword\":\"nightbreak\",\"strokecount\":5,\"framenum\":30,\"id\":26086}],\"dbg_generation_time\":\"562\"}"
}
