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
    
    let database = SwiftXDbReset(databaseName: "test_database")
    override func setUp() {
        super.setUp()
    }
    override func tearDown() {
        super.tearDown()
    }
    
    func testAdd(){
        let maxItem = 1000
        var dataOrg : Set<Int> = []
        for i in 0..<maxItem{
            let object = TestClassSimple()
            object.primaryKey = NSNumber(value:i)
            object.num = NSNumber(value:i)
            dataOrg.insert(Int(object.primaryKey))
            
            let ok = database.transaction({(db:SwiftyDb) in
                db.addObject(object, true).isSuccess
            })
        }
    }
    
    func testGet(){
        let maxItem = 1000
        for i in 0..<maxItem{
            let object = TestClassSimple()
            object.primaryKey = NSNumber(value:i)
            let filter = Filter.equal("primaryKey", value:object.primaryKey)
            let ret = database.objectsFor(object, filter)
        }
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























