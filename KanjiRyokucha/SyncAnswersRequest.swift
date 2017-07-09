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

struct CardSyncModel: Gloss.Encodable {
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

fileprivate struct SyncRoot: Gloss.Encodable {
    let answers: [CardSyncModel]

    func toJSON() -> JSON? {
        return jsonify([
            "time" ~~> Int(0),
            "sync" ~~> answers.toJSONArray()
            ])
    }
}

struct SyncResultModel: Gloss.Decodable {
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
        
        if Global.isGuest() {
            guestSync()
        }
    }
    
    var jsonObject: Gloss.Encodable? {
        return SyncRoot(answers: answers)
    }
    
    var guestResult: String? {
        let allIds = answers.map {$0.cardId}
        return "{ \"put\": \(allIds) }"
    }
    
    func guestSync() {
        let nos = answers.filter({ $0.answer == .no }).map{$0.cardId}
        let yeses = answers.filter({ $0.answer == .yes || $0.answer == .easy ||  $0.answer == .hard }).map{$0.cardId}
        let dels = answers.filter({ $0.answer == .delete }).map{$0.cardId}
        
        let answered = nos + yeses + dels
        
        GuestData.dueIds = GuestData.dueIds.removing(answered)
        GuestData.failedIds = GuestData.failedIds.removing(answered)
        GuestData.studyIds = nos
    }
}
