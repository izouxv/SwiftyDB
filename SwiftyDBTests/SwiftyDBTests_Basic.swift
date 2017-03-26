//
//  SwiftyDBTests.swift
//  SwiftyDBTests
//
//  Created by zouxu on 13/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//


import Quick
import Nimble

@testable import SwiftyDB

class SwiftXDb_Basic: XCTestCase {
    
    var database : swiftyDb!
    var maxItem : Int = 10000
    
    override func setUp() {
        //每个函数的执行都会调用这个
        database = SwiftXDbReset(databaseName: "test_databa123123se")
        super.setUp()
    }
    override func tearDown() {
        database.close()
        super.tearDown()
    }
    
    func testAdd(){
        
        let object = TestClassSimple()
        object.primaryKey = NSNumber(value:100)
        object.num = NSNumber(value:1000)
        _=database.addObject(object, true)
        object.primaryKey = NSNumber(value:110)
        object.num = NSNumber(value:1200)
        _=database.addObject(object, true)
        
        //update one item
        let filter = Filter.equal("primaryKey", value:Int(object.primaryKey))
        _=database.updateObjectEles(TestClassSimple(), ["num":123], filter)
        var ret = database.objectsFor(object, filter)
        XCTAssertTrue(ret.isSuccess == true)
        XCTAssertTrue(ret.value?.count == 1, "count: \(ret.value?.count)")
        XCTAssertTrue(ret.value?[0].num == 123)
        
        //update all items
        _=database.updateObjectEles(TestClassSimple(), ["num":321], nil)
        ret = database.objectsFor(object)
        XCTAssertTrue(ret.isSuccess == true)
        XCTAssertTrue(ret.value?.count == 2, "count: \(ret.value?.count)")
        XCTAssertTrue(ret.value?[0].num == 321)
        XCTAssertTrue(ret.value?[1].num == 321)
        
    }
}
















