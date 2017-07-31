//
//  KanjiRyokuchaTests.swift
//  KanjiRyokuchaTests
//
//  Created by German Buela on 11/26/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import XCTest
@testable import KanjiRyokucha

public typealias JSON = [String : Any]

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
        let model = DummyModel(ownerId: 495, username: "pepito")
        let encoder = JSONEncoder()
        let jsonData = try! encoder.encode(model)
        let theJSONText = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)!
        print(theJSONText)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

struct DummyModel: Codable {
    let ownerId: Int?
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case ownerId = "id"
        case username = "login"
    }
}
