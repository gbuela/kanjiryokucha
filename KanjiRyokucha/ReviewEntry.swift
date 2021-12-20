//
//  ReviewEntry.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/8/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
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
    @objc dynamic var cardId = 0
    @objc dynamic var rawAnswer = 0
    @objc dynamic var keyword = ""
    @objc dynamic var frameNumber = 0
    @objc dynamic var strokeCount = 0
    @objc dynamic var submitted = false
    
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
