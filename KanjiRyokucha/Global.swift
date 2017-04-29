//
//  Global.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/5/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import RealmSwift
import ReactiveSwift

enum ReviewType: Int {
    case expired = 1
    case new = 2
    case failed = 3
    
    var colors: ButtonColors {
        switch self {
        case .expired:
            return expiredColors
        case .new:
            return newColors
        case .failed:
            return failedColors
        }
    }
    
    var displayText: String {
        switch self {
        case .expired:
            return "due cards"
        case .new:
            return "new cards"
        case .failed:
            return "failed cards"
        }
    }
    
    static let allTypes: [ReviewType] = [.expired, .new, .failed]
}

let defaultSyncLimit = 25

class Global : Object {
    
    static var username = ""
    static let requestDelaySeconds = 1.0
    static var latestRequestDate: Date?
    
    static func isGuest() -> Bool {
        return username == guestUsername
    }
    
    dynamic var refreshNeeded = false
    let studyPhaseProperty = MutableProperty(true)
    
    dynamic var id = 0
    let reviewType = RealmOptional<Int>()
    dynamic var useAnimations = true
    dynamic var useStudyPhase = true
    dynamic var syncLimit = defaultSyncLimit

    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["refreshNeeded", "studyPhaseProperty"]
    }
}
