//
//  Global.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/5/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
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
    
    @objc dynamic var refreshNeeded = false
    let studyPhaseProperty = MutableProperty(true)
    
    @objc dynamic var id = 0
    let reviewType = RealmOptional<Int>()
    @objc dynamic var useAnimations = true
    @objc dynamic var useStudyPhase = true
    @objc dynamic var useNotifications = false
    @objc dynamic var syncLimit = defaultSyncLimit
    @objc dynamic var latestDueCount = 0

    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["refreshNeeded", "studyPhaseProperty"]
    }
}
