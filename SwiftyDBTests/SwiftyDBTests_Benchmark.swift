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

class SwiftXDb_Benchmark: SwiftyDBSpec {
    override func spec() {
        super.spec()
        let maxItem = 1000
        let database = SwiftXDbReset(databaseName: "test_database")
        describe("single") {
            context("sample \(maxItem)") {
                it("add") {
                    var dataOrg : Set<Int> = []
                    for i in 0..<maxItem{
                        let object = TestClassSimple()
                        object.primaryKey = NSNumber(value:i)
                        object.num = NSNumber(value:i)
                        dataOrg.insert(Int(object.primaryKey))
                        
                        let ok = database.transaction({(db:SwiftyDb) in
                            expect(db.addObject(object, true).isSuccess).to(beTrue())
                        })
                        expect(ok) == true
                    }
                }
                it("getsql") {
                    let object = TestClassSimple()
                    for i in 0..<maxItem{
                        object.primaryKey = NSNumber(value:i)
                        let filter = Filter.equal("primaryKey", value:object.primaryKey)
                        let ret = database.objectsFor(object, filter)
                        expect(ret.isSuccess).to(beTrue())
                        expect(ret.value?.count) == 1
                        expect(ret.value?[0].num) == object.primaryKey
                        expect(database.objectsFor(object).isSuccess).to(beTrue())
                    }
                }
//                it("get") {
//                    let object = TestClassSimple()
//                    for i in 0..<maxItem{
//                        object.primaryKey = NSNumber(value:i)
//                        let filter = Filter.equal("primaryKey", value:object.primaryKey)
//                        let ret = database.objectsFor(object, filter)
//                        expect(ret.isSuccess).to(beTrue())
//                        expect(ret.value?.count) == 1
//                        expect(ret.value?[0].num) == object.primaryKey
//                        expect(database.objectsFor(object).isSuccess).to(beTrue())
//                    }
//                }
            }
        }
    }
}

































