//
//  ReviewEntry.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/8/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import RealmSwift

enum CardAnswer: Int {
    case unanswered = 0
    case no = 1
    case yes = 2
    case easy = 3
    case delete = 4
    case skip = 5
    case hard = 6
}

class ReviewEntry : Object {
    dynamic var cardId = 0
    dynamic var rawAnswer = 0
    dynamic var keyword = ""
    dynamic var frameNumber = 0
    dynamic var strokeCount = 0
    dynamic var submitted = false
    
    var cardAnswer: CardAnswer {
        get {
            if let answer = CardAnswer(rawValue: rawAnswer) {
                return answer
            } else {
                return .unanswered
            }
        }
        set {
            rawAnswer = newValue.rawValue
        }
    }
    
    override static func primaryKey() -> String? {
        return "cardId"
    }
}
