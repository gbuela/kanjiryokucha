//
//  KanjiRyokuchaTests.swift
//  KanjiRyokuchaTests
//
//  Created by German Buela on 11/26/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import XCTest
@testable import KanjiRyokucha
import Gloss

class KanjiRyokuchaTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let jori: JSON = ["id":495, "login":"pepito"]
        let model = DummyModel(json: jori)
        let j = model!.toJSON()!
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: j, options: .prettyPrinted)
            let theJSONText = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
            print(theJSONText)

        } catch {
            
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

struct DummyModel: Glossy {
    let ownerId: Int?
    let username: String?
    
    init?(json: JSON) {
        self.ownerId = "id" <~~ json
        self.username = "login" <~~ json
    }
    
    func toJSON() -> JSON? {
        return jsonify([
            "id" ~~> self.ownerId,
            "login" ~~> self.username
            ])
    }

}
