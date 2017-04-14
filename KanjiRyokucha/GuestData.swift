//
//  GuestData.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/11/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

let k0: JSON = ["keyword": "one", "strokecount": 1, "framenum": 1, "id": 19968]
let k1: JSON = ["keyword": "two", "strokecount": 2, "framenum": 2, "id": 20108]
let k2: JSON = ["keyword": "three", "strokecount": 3, "framenum": 3, "id": 19977]
let k3: JSON = ["keyword": "four", "strokecount": 5, "framenum": 4, "id": 22235]
let k4: JSON = ["keyword": "five", "strokecount": 4, "framenum": 5, "id": 20116]
let k5: JSON = ["keyword": "six", "strokecount": 4, "framenum": 6, "id": 20845]
let k6: JSON = ["keyword": "seven", "strokecount": 2, "framenum": 7, "id": 19971]
let k7: JSON = ["keyword": "eight", "strokecount": 2, "framenum": 8, "id": 20843]
let k8: JSON = ["keyword": "nine", "strokecount": 2, "framenum": 9, "id": 20061]
let k9: JSON = ["keyword": "ten", "strokecount": 2, "framenum": 10, "id": 21313]

struct GuestData {
    static var dueIds: [Int] = []
    static var failedIds: [Int] = []
    static var studyIds: [Int] = []
    static var useStudyPhase = true
    
    static var cardData: [CardModel] = [
        CardModel(json: k0)!,
        CardModel(json: k1)!,
        CardModel(json: k2)!,
        CardModel(json: k3)!,
        CardModel(json: k4)!,
        CardModel(json: k5)!,
        CardModel(json: k6)!,
        CardModel(json: k7)!,
        CardModel(json: k8)!,
        CardModel(json: k9)!
    ]
    
    static var reviewableFailedIds: [Int] {
        if useStudyPhase {
            return failedIds
        } else {
            return failedIds + studyIds
        }
    }
    
    static func cardModel(forId id: Int) -> CardModel {
        let card = cardData.first(where: {$0.cardId == id})
        return card!
    }
    
    static func reset() {
        dueIds = cardData.map {$0.cardId}
        failedIds = []
        studyIds = []
    }
}
