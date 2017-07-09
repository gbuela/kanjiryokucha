//
//  SyncStudyRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/26/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

fileprivate struct SyncRoot: Gloss.Encodable {
    let learned: [Int]
    let notLearned: [Int]
    
    func toJSON() -> JSON? {
        return jsonify([
            "learned" ~~> learned,
            "notLearned" ~~> notLearned
        ])
    }
}

struct SyncStudyResultModel: Gloss.Decodable {
    let putLearned: [Int]
    let putNotLearned: [Int]
    
    init?(json: JSON) {
        guard let learned: [Int] = "putLearned" <~~ json,
            let notLearned: [Int] = "putNotLearned" <~~ json else { return nil }
        
        putLearned = learned
        putNotLearned = notLearned
    }
}

struct SyncStudyRequest: KoohiiRequest {
    let learned: [Int]
    let notLearned: [Int]
    
    typealias ModelType = SyncStudyResultModel
    let apiMethod = "study/sync"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.post
    let contentType = ContentType.json
    
    var jsonObject: Gloss.Encodable? {
        return SyncRoot(learned: learned, notLearned: notLearned)
    }
    
    var guestResult: String? {
        if Global.isGuest() { updateGuestData() }
        return "{ \"putLearned\": \(learned.description), \"putNotLearned\": \(notLearned.description)}"
    }
    
    private func updateGuestData() {
        GuestData.failedIds.append(contentsOf: learned)
        GuestData.studyIds = GuestData.studyIds.removing(learned)
        
        GuestData.studyIds.append(contentsOf: notLearned)
        GuestData.failedIds = GuestData.failedIds.removing(notLearned)
    }
}
