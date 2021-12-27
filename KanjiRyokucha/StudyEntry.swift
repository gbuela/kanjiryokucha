//
//  StudyEntry.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/15/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import RealmSwift

class StudyEntry : Object {
    @objc dynamic var cardId = 0
    let frameNum = RealmOptional<Int>()
    @objc dynamic var keyword = ""
    @objc dynamic var learned = false
    @objc dynamic var synced = false

    override static func primaryKey() -> String? {
        return "cardId"
    }
}
