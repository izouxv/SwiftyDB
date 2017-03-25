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

class SwiftXDb_Benchmark: XCTestCase {
    
    var database : swiftyDb!
    var maxItem : Int = 10000
    
    override func setUp() {
        //每个函数的执行都会调用这个
        database = SwiftXDb(databaseName: "test_databa123123se")
        super.setUp()
    }
    override func tearDown() {
        database.close()
        super.tearDown()
    }
    
    func testAdd(){
        for i in 0..<maxItem{
            let object = TestClassSimple()
            object.primaryKey = NSNumber(value:i)
            object.num = NSNumber(value:i)
            
            let ok = database.transaction({(db:SwiftyDb, rollback:inout Bool) in
                let suc = db.addObject(object, true).isSuccess
                XCTAssertTrue(suc == true)
            })
            XCTAssertTrue(ok == true)
        }
    }
    
    func testGet(){
        for i in 0..<maxItem{
            let object = TestClassSimple()
            object.primaryKey = NSNumber(value:i)
            let filter = Filter.equal("primaryKey", value:Int(object.primaryKey))
            let ret = database.objectsFor(object, filter)
            
            XCTAssertTrue(ret.isSuccess == true)
            XCTAssertTrue(ret.value?.count == 1, "count: \(ret.value?.count)")
            XCTAssertTrue(ret.value?[0].num == object.primaryKey)
        }
    }
}

/*
 extension SwiftXDb_Property{
 func testProperty() {
 let object = TestClass()
 object.loadSampleData()
 self.measure() {
 for _ in 0...100{
 _=PropertyData.validPropertyDataForObject(object)
 }
 }
 }
 func testProperty_MirrorChildren() {
 let object = TestClass()
 object.loadSampleData()
 self.measure() {
 for _ in 0...100{
 for property in Mirror(reflecting: object).children {
 //   print("name: \(property.label) type: \(type(of: property.value)) value: \(property.value)")
 }
 }
 }
 }
 func testProperty_Mirror() {
 let object = TestClass()
 object.loadSampleData()
 self.measure() {
 for _ in 0...100{
 Mirror(reflecting: object)
 }
 }
 }
 }
 
 */



















