//
//  StudyRefreshRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/25/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation

struct StudyIdsModel: Decodable {
    let ids: [Int]
    let learnedIds: [Int]
    
    enum CodingKeys: String, CodingKey {
        case ids = "items"
        case learnedIds = "learnedItems"
    }
}

struct StudyRefreshRequest: KoohiiRequest {
    typealias ModelType = StudyIdsModel
    typealias InputType = NoInput
    let apiMethod = "study/info"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
    
    var guestResult: String? {
        let allFailed = GuestData.failedIds + GuestData.studyIds
        return "{\"items\": \(allFailed.description), \"learnedItems\": \(GuestData.failedIds)}"
    }
}
