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

class SwiftXDbMutiThread: SwiftyDBSpec {
    override func spec() {
        super.spec()
        let database = SwiftXDb(databaseName: "test_database")
        describe("Data in database is updated") {
            context("object added test sample data") {
                it("muti thread add") {
                    var dataOrg : Set<Int> = []
                    let maxItem = 1000
                    var doneCount : Int32 = 0
                    let curRunloop = CFRunLoopGetCurrent()
                    for i in 0..<maxItem{
                        let object = TestClassSimple()
                        object.primaryKey = NSNumber(value:i)
                        object.num = Int(arc4random()%20)
                        dataOrg.insert(Int(object.primaryKey))
                        DispatchQueue.global().async{
                            let done = OSAtomicAdd32(Int32(1), &doneCount)
                            Swift.print("start: \(done)")
//                            expect(database.addObject(object).isSuccess).to(beTrue())
                            database.transaction({ (db:SwiftyDb) in
                                expect(db.addObject(object, true).isSuccess).to(beTrue())
                                expect(db.addObject(object, true).isSuccess).to(beTrue())
                            })
                            Swift.print("add done: \(done)")
                            if done == Int32(maxItem){
                                CFRunLoopStop(curRunloop)
                            }
                        }
                    }
                    CFRunLoopRun();
                    expect(database.dataFor(TestClassSimple()).value?.count) == maxItem
                    let items = database.objectsFor(TestClassSimple()).value 
                    let names : Set<Int> = Set(items!.map{Int($0.primaryKey)})
                    expect(names == dataOrg) == true
                    
                }
                it("muti thread get") {
                    var dataOrg : Set<Int> = []
                    let maxItem = 1000
                    var doneCount : Int32 = 0
                    let curRunloop = CFRunLoopGetCurrent()
                    for i in 0..<maxItem{
                        let object = TestClassSimple()
                        object.primaryKey = NSNumber(value:i)
                        object.num = Int(arc4random()%20)
                        dataOrg.insert(Int(object.primaryKey))
                        DispatchQueue.global().async{
                            let done = OSAtomicAdd32(Int32(1), &doneCount)
                            Swift.print("start: \(done)")
                            expect(database.objectsFor(object).isSuccess).to(beTrue())
                            Swift.print("get done: \(done)")
                            if done == Int32(maxItem){
                                CFRunLoopStop(curRunloop)
                            }
                        }
                    }
                    CFRunLoopRun();
                    expect(database.dataFor(TestClassSimple()).value?.count) == maxItem
                    let items = database.objectsFor(TestClassSimple()).value
                    let names : Set<Int> = Set(items!.map{Int($0.primaryKey)})
                    expect(names == dataOrg) == true
                    
                }
            }
        }
    }
}

































