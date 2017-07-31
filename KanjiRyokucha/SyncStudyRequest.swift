//
//  SyncStudyRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/26/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation

struct SyncRoot: Encodable {
    let learned: [Int]
    let notLearned: [Int]
}

struct SyncStudyResultModel: Decodable {
    let putLearned: [Int]
    let putNotLearned: [Int]
}

struct SyncStudyRequest: KoohiiRequest {
    let learned: [Int]
    let notLearned: [Int]
    
    typealias ModelType = SyncStudyResultModel
    typealias InputType = SyncRoot
    let apiMethod = "study/sync"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.post
    let contentType = ContentType.json
    
    var jsonObject: SyncRoot? {
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
