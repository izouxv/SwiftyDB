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



//class SwiftXDbMutiThread: XCTestCase {
//    override func setUp() {
//        super.setUp()
//    }
//    override func tearDown() {
//        super.tearDown()
//    }
//    func checkData(_ org :  Set<String>, _ dbdata: [TestClassSimple]){
//        
//    }
//    func testWaOverride() {
//        let database = SwiftXDb(databaseName: "test_database")
//        let maxItem = 1000
//        var doneCount : Int32 = 0
//        let curRunloop = CFRunLoopGetCurrent()
//        var dataOrg : Set<String> = []
//        for i in 0..<maxItem{
//            let object = TestMigrateVer0()
//            let name = "name_\(i)"
//            dataOrg.insert(name)
//            object.name = name
//            DispatchQueue.global().async{
//                let done = OSAtomicAdd32(Int32(1), &doneCount)
//                expect(database.addObject(object).isSuccess).to(beTrue())
//                Swift.print("done: \(done)")
//                if done == Int32(maxItem){
//                    CFRunLoopStop(curRunloop)
//                }
//            }
//        }
//        CFRunLoopRun();
//        expect(database.dataFor(TestClassSimple()).value?.count) == maxItem
//        checkData()
//    }
//}
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
                            expect(database.addObject(object).isSuccess).to(beTrue())
                            Swift.print("done: \(done)")
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
                    
                   // expect(names.) == maxItem
                }
            }
        }
    }
}

































