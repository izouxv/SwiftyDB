//
//  SwiftyDBTests.swift
//  SwiftyDBTests
//
//  Created by zouxu on 13/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//

//import XCTest
//@testable import SwiftyDB
//
//class SwiftyDBTests_Filter: XCTestCase {
//
//    override func setUp() {
//        super.setUp()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//    }
//
//    func testExample() {
//        let f = Filter.contains("123", array: [1,2]).orderBy(["a", "b", "c"]).limit(10).offset(100)
//        let str = StatementGenerator.deleteStatementForType(SwiftyDBTests_Filter(), matchingFilter: f)
//        Swift.print("\(str)")
//
//    }
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//}


import SwiftyDB
import Quick
import Nimble

class SwiftyDbFilter: SwiftyDBSpec {
    override func spec() {
        super.spec()
        let database = SwiftyDbX(databaseName: "test_database")
        describe("Data in database is updated") {
            context("object added test sample data") {
                it("should contain the object after it is added") {
                    for i in 0..<10{
                        let object = TestClassSimple()
                        object.primaryKey = NSNumber(value:i)
                        object.num = Int(arc4random()%20)
                        expect(database.addObject(object).isSuccess).to(beTrue())
                    }
                    expect(database.dataForType(TestClassSimple()).value?.count) == 10
                }
                it("limit greate than data") {
                    let filter = Filter.greaterThan("primaryKey", value: 3).orderBy(["num DESC"]).limit(3)
                    let value = database.dataForType(TestClassSimple(), matchingFilter: filter).value
                    Swift.print("value: \(value?.description)")
                    expect(value?.count) == 3
                }
                it("limit greate than data") {
                    let filter = Filter.greaterThan("primaryKey", value: 3).orderBy(["num"]).limit(3)
                    let value = database.dataForType(TestClassSimple(), matchingFilter: filter).value
                    Swift.print("value: \(value?.description)")
                    expect(value?.count) == 3
                }
                
                it("limit less than data") {
                    let filter = Filter.greaterThan("primaryKey", value: 8).orderBy(["num DESC"]).limit(3)
                    let value = database.dataForType(TestClassSimple(), matchingFilter: filter).value
                    Swift.print("value: \(value?.description)")
                    expect(value?.count) == 1
                }
                
                
            }
        }
    }
}

































