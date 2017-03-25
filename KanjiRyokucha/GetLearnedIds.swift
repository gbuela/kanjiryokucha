//
//  GetLearnedIds.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/24/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

struct GetLearnedIds: Decodable {
    let cardIds: [Int]
    
    init?(json: JSON) {
        guard let ids: [Int] = "ids" <~~ json else {
                return nil
        }
        print(json)
        self.cardIds = ids
    }
}

struct GetLearnedIdsRequest: KoohiiRequest {
    typealias ModelType = GetLearnedIds
    let apiMethod = "srs/learned"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
}
