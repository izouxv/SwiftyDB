//
//  SwiftDBTests.swift
//  SwiftDBTests
//
//  Created by zouxu on 3/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//


@testable import SwiftyDB
import Quick
import Nimble


class SwiftXDbMigrate: SwiftyDBSpec {
    override func spec() {
        super.spec()
        
        expect(keyWordSet.count) == 121
        
        var database = SwiftXDb(databaseName: "test_database")
        
        let obj1 = TestMigrateVer0()
        obj1.name = "this is name"
        obj1.age = "16"
        obj1.email = "izouxv@gmail.com"
        
        describe("test db migrate ver 0->1->2") {
            
            context("add version 0 obj to db") {
                _=database.addObject(obj1)
            }
            
            var newVersion = 1
            context("migrate version 0->1") {
                let database = SwiftXDb(databaseName: "test_database")
                database.MigrateAction(newVersion, [TestMigrateVer1()])
                
                let fff : SwiftyDB.Filter = ["name": obj1.name]
                let res = database.objectsFor(TestMigrateVer1(), fff)
                
                expect(res.value?.count) == 1
                expect(res.value![0].age) == 16
            }
            
            newVersion = 2
            context("migrate version 1->2") {
                let database = SwiftXDb(databaseName: "test_database")
                database.MigrateAction(newVersion, [TestMigrateVer2()])
                
                let fff : SwiftyDB.Filter =  ["name": obj1.name]
                let res = database.objectsFor(TestMigrateVer2(),fff)
                
                expect(res.value?.count) == 1
                let item = res.value![0]
                expect(item.age) == 100
                expect(item.nikeName) == "default"
                expect(item.Address) == "Add"
            }
        }
        
        database = SwiftXDbReset(databaseName: "test_database")
        describe("test db migrate ver 0->2") {
            context("add version 0 obj to db") {
                _=database.addObject(obj1)
            }
            
            let newVersion = 2
            context("migrate version 0->2") {
                
                let database = SwiftXDb(databaseName: "test_database")
                let checkUpgrade = database.MigrateCheck(newVersion, [TestMigrateVer0_2()])
                expect(checkUpgrade) == true
                
                database.MigrateAction(newVersion, [TestMigrateVer0_2()])
                let fff : SwiftyDB.Filter =  ["name": obj1.name]
                let res = database.objectsFor(TestMigrateVer2(), fff)
                
                expect(res.value?.count) == 1
                let item = res.value![0]
                expect(item.age) == 100
                expect(item.nikeName) == "default"
                expect(item.Address) == "Add"
                
            }
        }
    }
}

















