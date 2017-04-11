//
//  SyncAnswersRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 1/1/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

extension CardAnswer {
    var backendRequiresString: Bool {
        return self == .hard
    }
    var srtingForBackend: String? {
        return self == .hard ? "h" : nil
    }
    var intForBackend: Int {
        return self.rawValue
    }
}

struct CardSyncModel: Encodable {
    let cardId: Int
    let answer: CardAnswer
    
    func toJSON() -> JSON? {
        var valueForBackend: Any
        if answer.backendRequiresString,
            let stringValue = answer.srtingForBackend {
            valueForBackend = stringValue
        } else {
            valueForBackend = answer.intForBackend
        }
        
        return jsonify([
            "id" ~~> cardId,
            "r" ~~> valueForBackend
            ])
    }
}

fileprivate struct SyncRoot: Encodable {
    let answers: [CardSyncModel]

    func toJSON() -> JSON? {
        return jsonify([
            "time" ~~> Int(0),
            "sync" ~~> answers.toJSONArray()
            ])
    }
}

struct SyncResultModel: Decodable {
    let putIds: [Int]
    
    init?(json: JSON) {
        guard let put: [Int] = "put" <~~ json else {
            return nil
        }
  
        putIds = put
    }
}

struct SyncAnswersRequest: KoohiiRequest {
    let answers: [CardSyncModel]
    
    typealias ModelType = SyncResultModel
    let apiMethod = "review/sync"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.post
    let contentType = ContentType.json
    
    init(answers: [CardSyncModel]) {
        self.answers = answers
    }
    
    var jsonObject: Encodable? {
        return SyncRoot(answers: answers)
    }
    
    let guestResult: String? = ""
}
