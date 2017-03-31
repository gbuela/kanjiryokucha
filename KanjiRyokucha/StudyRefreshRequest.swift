//
//  StudyRefreshRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/25/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

struct StudyIdsModel: Decodable {
    let ids: [Int]
    let learnedIds: [Int]
    
    init?(json: JSON) {
        guard let items:[Int] = "items" <~~ json,
            let learnedItems:[Int] = "learnedItems" <~~ json else {
            return nil
        }
        ids = items
        learnedIds = learnedItems
    }
}

struct StudyRefreshRequest: KoohiiRequest {
    typealias ModelType = StudyIdsModel
    let apiMethod = "study/info"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
}
