//
//  SyncAnswersRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 1/1/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation

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

struct CardSyncModel {
    let cardId: Int
    let answer: CardAnswer
}

struct SyncAnswer: Encodable {
    let cardSyncModel: CardSyncModel
    
    init(cardSyncModel: CardSyncModel) {
        self.cardSyncModel = cardSyncModel
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cardSyncModel.cardId, forKey: .id)
        
        if cardSyncModel.answer.backendRequiresString,
            let stringValue = cardSyncModel.answer.srtingForBackend {
            try container.encode(stringValue, forKey: .r)
        } else {
            try container.encode(cardSyncModel.answer.intForBackend, forKey: .r)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case r
    }
}
struct SyncAnswersRoot: Encodable {
    
    let time: Int
    let sync: [SyncAnswer]
    
    init(answers: [CardSyncModel]) {
        self.time = 0
        self.sync = answers.map { SyncAnswer(cardSyncModel: $0) }
    }
}

struct SyncResultModel: Decodable {
    let putIds: [Int]
    
    enum CodingKeys: String, CodingKey {
        case putIds = "put"
    }
}

struct SyncAnswersRequest: KoohiiRequest {
    let answers: [CardSyncModel]
    
    typealias ModelType = SyncResultModel
    typealias InputType = SyncAnswersRoot
    let apiMethod = "review/sync"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.post
    let contentType = ContentType.json
    
    init(answers: [CardSyncModel]) {
        self.answers = answers
    }
    
    var jsonObject: SyncAnswersRoot? {
        return SyncAnswersRoot(answers: answers)
    }
}
