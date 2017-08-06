//
//  RealmMigration.swift
//  KanjiRyokucha
//
//  Created by German Buela on 6/11/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import RealmSwift

extension Realm {
    class func ConfigurationWithMigration() -> Realm.Configuration {
        return Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // adding frameNum to StudyEntry
                } else if oldSchemaVersion < 2 {
                    // adding useNotifications to Global
                }
        })
    }
}
