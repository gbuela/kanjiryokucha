//
//  CardFetchRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/24/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation

struct CardModel: Decodable {
    let keyword: String
    let strokeCount: Int
    let frameNum: Int
    let cardId: Int
    
    enum CodingKeys: String, CodingKey {
        case keyword
        case strokeCount = "strokecount"
        case frameNum = "framenum"
        case cardId = "id"
    }
}

struct CardDataModel: Decodable {
    let cards: [CardModel]
    
    static func nullObject() -> CardDataModel {
        return CardDataModel(cards: [])
    }
    
    enum CodingKeys: String, CodingKey {
        case cards = "card_data"
    }
}

struct CardFetchRequest: KoohiiRequest {
    let qsParams: ParamSet
    let cardFetchLimit = 10
    
    typealias ModelType = CardDataModel
    typealias InputType = NoInput
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
}
