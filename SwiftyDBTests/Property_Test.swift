//
//  SwiftyDBTests.swift
//  SwiftyDBTests
//
//  Created by zouxu on 13/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//


@testable import SwiftyDB
import Quick
import Nimble


class SwiftXDb_Property: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testProperty() {
        let object = TestClass()
        object.loadSampleData()
        self.measure() {
            for _ in 0...100{
                _=PropertyData.validPropertyDataForObject(object)
            }
        }
    }
}






























