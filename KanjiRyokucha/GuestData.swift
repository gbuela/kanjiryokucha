//
//  GuestData.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/11/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

let k0: JSON = ["keyword": "span", "strokecount":6,"framenum":32,"id":20120]
let k1: JSON = ["keyword": "risk", "strokecount":9,"framenum":18,"id":20882]
let k2: JSON = ["keyword": "rise up", "strokecount":8,"framenum":43,"id":26119]
let k3: JSON = ["keyword": "bright", "strokecount":8,"framenum":20,"id":26126]
let k4: JSON = ["keyword": "measuring box", "strokecount":4,"framenum":42,"id":21319]
let k5: JSON = ["keyword": "month", "strokecount":4,"framenum":13,"id":26376]
let k6: JSON = ["keyword": "three", "strokecount":3,"framenum":3,"id":19977]
let k7: JSON = ["keyword": "round", "strokecount":3,"framenum":44,"id":20024]
let k8: JSON = ["keyword": "nightbreak", "strokecount":5,"framenum":30,"id":26086]
let k9: JSON = ["keyword": "six","strokecount":4,"framenum":6,"id":20845]

struct GuestData {
    static var dueIds: [Int] = []
    static var failedIds: [Int] = []
    static var studyIds: [Int] = []
    
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
    
    static func cardModel(forId id: Int) -> CardModel {
        let card = cardData.first(where: {$0.cardId == id})
        return card!
    }
    
    static func reset() {
        dueIds = [20845,26119,20120,26126,20882,19977,26376,20024,21319]
        failedIds = []
        studyIds = []
    }
}
