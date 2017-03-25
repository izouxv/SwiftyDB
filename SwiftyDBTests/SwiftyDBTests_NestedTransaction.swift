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

fileprivate func object(_ num : Int, _ num2: Int)->TestClassSimple{
    let obj = TestClassSimple()
    obj.primaryKey = NSNumber(value:num)
    obj.num = NSNumber(value:num2)
    return obj
}

class SwiftXDb_NestedTransaction: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    override func tearDown() {
        super.tearDown()
    }
    func testNestedTransaction_AllDone(){
        let database = SwiftXDbReset(databaseName: "test_databasesfd")
        let ok0 = database.transaction { (db1:SwiftyDb, rollback:inout Bool) in
            let ok1 = db1.addObject(object(10, 10), true).isSuccess
            _=db1.addObject(object(11, 11), true)
            XCTAssertTrue(ok1 == true)
            let ok2 = db1.transaction({ (db2:SwiftyDb, rollback:inout Bool) in
                let ok3 = db1.addObject(object(20, 20), true).isSuccess
                _=db1.addObject(object(21, 21), true)
                XCTAssertTrue(ok3 == true)
                let ok4 = db2.transaction({ (db3:SwiftyDb, rollback:inout Bool) in
                    let ok5 = db3.addObject(object(30, 30), true).isSuccess
                    _=db1.addObject(object(31, 31), true)
                    XCTAssertTrue(ok5 == true)
                })
                XCTAssertTrue(ok4 == true)
            })
            XCTAssertTrue(ok2 == true)
        }
        XCTAssertTrue(ok0 == true)
        
        let ret = database.objectsFor(TestClassSimple())
        XCTAssertTrue(ret.isSuccess == true)
        let items = ret.value
        XCTAssertTrue(items!.count == 6)
        let names : Set<Int> = Set(items!.map{Int($0.primaryKey)})
        XCTAssertTrue(names == Set<Int>([10,11,20,21,30,31]))
    }
    
    func testNestedTransaction_HalfDone(){
        let database = SwiftXDbReset(databaseName: "test_databasesfd")
        let ok0 = database.transaction {(db1:SwiftyDb, rollback:inout Bool) in
            let ok1 = db1.addObjects([object(10, 10),object(11, 11)], true).isSuccess
            XCTAssertTrue(ok1 == true)
            let ok2 = db1.transaction({ (db2:SwiftyDb, rollback:inout Bool) in
                let ok3 = db1.addObject(object(20, 20), true).isSuccess
                XCTAssertTrue(ok3 == true)
                let ok4 = db2.transaction({ (db3:SwiftyDb, rollback:inout Bool) in
                    let ok5 = db3.addObject(object(20, 30), false).isSuccess
                    XCTAssertTrue(ok5 == false)
                    let ok6 = db3.addObject(object(30, 30), false).isSuccess
                    XCTAssertTrue(ok6 == true)
                    rollback = true
                })
                XCTAssertTrue(ok4 == false)
            })
            XCTAssertTrue(ok2 == true)
        }
        XCTAssertTrue(ok0 == true)
        
        let ret = database.objectsFor(TestClassSimple())
        XCTAssertTrue(ret.isSuccess == true)
        let items = ret.value
        XCTAssertTrue(items!.count == 3)
        let names : Set<Int> = Set(items!.map{Int($0.primaryKey)})
        XCTAssertTrue(names == Set<Int>([10,11,20]))
    }
}




























