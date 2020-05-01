//
//  Database.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/4/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import RealmSwift

struct Database {
    
    static func getGlobal() -> Global {
        do {
            let realm = try Realm()
            let global = realm.objects(Global.self).first ?? Global()
            global.studyPhaseProperty.value = global.useStudyPhase
            return global
        } catch {
            // TODO: db fail
            log("Realm failed: \(error.localizedDescription)")
            return Global()
        }
    }
    
    static func write(closure: ((Realm) -> ())) {
        do {
            let realm = try Realm()
            try realm.write {
                closure(realm)
            }
        } catch {
            // TODO: db fail
            log("Realm failed: \(error.localizedDescription)")
        }
    }
    
    // TODO: write in transaction on background thread
    // https://realm.io/docs/swift/latest/#background-operations

    static func write(object: Object, closure: (() -> ())) {
        do {
            let realm = try Realm()
            try realm.write {
                closure()
                realm.add(object, update: .all)
            }
        } catch {
            // TODO: db fail
            log("Realm failed: \(error.localizedDescription)")
        }
    }
    
    static func write<S: Sequence>(objects: S, closure: ((Realm) -> ())) where S.Iterator.Element: Object {
        do {
            let realm = try Realm()
            try realm.write {
                closure(realm)
                realm.add(objects, update: .all)
            }
        } catch {
            // TODO: db fail
            log("Realm failed: \(error.localizedDescription)")
        }
    }
    
    static func delete<S: Sequence>(objects: S) where S.Iterator.Element: Object {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(objects)
            }
        } catch {
            // TODO: db fail
            log("Realm failed: \(error.localizedDescription)")
        }
    }
    
    static func readAllForType<T: Object>() -> [T] {
        do {
            let realm = try Realm()
            return Array(realm.objects(T.self))
        } catch {
            // TODO: db fail
            log("Realm failed: \(error.localizedDescription)")
            return []
        }
    }
}
