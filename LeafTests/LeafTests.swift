//
//  LeafTests.swift
//  LeafTests
//
//  Created by hao yin on 2021/7/6.
//

import XCTest
@testable import Leaf
class LeafTests: XCTestCase {

    var loader = DataStorage()
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        loader.append(name: "a", data: "dadsadad".data(using: .utf8)!)
        
        loader.save(name: "a", data: "a".data(using: .utf8)!)
        print(String(data: try loader.read(name: "a"), encoding: .utf8))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
