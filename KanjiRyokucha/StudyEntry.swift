//
//  StudyEntry.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/15/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import RealmSwift

class StudyEntry : Object {
    dynamic var cardId = 0
    dynamic var keyword = ""
    dynamic var learned = false

    override static func primaryKey() -> String? {
        return "cardId"
    }
}
