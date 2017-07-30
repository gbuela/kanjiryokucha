//
//  GuestData.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/11/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation

let k0 = "\"keyword\": \"one\", \"strokecount\": 1, \"framenum\": 1, \"id\": 19968"
let k1 = "\"keyword\": \"two\", \"strokecount\": 2, \"framenum\": 2, \"id\": 20108"
let k2 = "\"keyword\": \"three\", \"strokecount\": 3, \"framenum\": 3, \"id\": 19977"
let k3 = "\"keyword\": \"four\", \"strokecount\": 5, \"framenum\": 4, \"id\": 22235"
let k4 = "\"keyword\": \"five\", \"strokecount\": 4, \"framenum\": 5, \"id\": 20116"
let k5 = "\"keyword\": \"six\", \"strokecount\": 4, \"framenum\": 6, \"id\": 20845"
let k6 = "\"keyword\": \"seven\", \"strokecount\": 2, \"framenum\": 7, \"id\": 19971"
let k7 = "\"keyword\": \"eight\", \"strokecount\": 2, \"framenum\": 8, \"id\": 20843"
let k8 = "\"keyword\": \"nine\", \"strokecount\": 2, \"framenum\": 9, \"id\": 20061"
let k9 = "\"keyword\": \"ten\", \"strokecount\": 2, \"framenum\": 10, \"id\": 21313"

struct GuestData {
    static var dueIds: [Int] = []
    static var failedIds: [Int] = []
    static var studyIds: [Int] = []
    static var useStudyPhase = true
    
    static let decoder = JSONDecoder()
    
    static var cardData: [CardModel] = [
        card(k0),
        card(k1),
        card(k2),
        card(k3),
        card(k4),
        card(k5),
        card(k6),
        card(k7),
        card(k8),
        card(k9)
    ]
    
    private static func card(_ jsonString: String) -> CardModel {
        let data = jsonString.data(using: .utf8)!
        return try! decoder.decode(CardModel.self, from: data)
    }
    
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
