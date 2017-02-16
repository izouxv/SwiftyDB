//
//  SwiftDBTests.swift
//  SwiftDBTests
//
//  Created by zouxu on 3/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//


import SwiftyDB
import Quick
import Nimble


class SwiftXDbMigrate: SwiftyDBSpec {
    override func spec() {
        super.spec()
        let database = SwiftXDb(databaseName: "test_database")
        describe("test db migrate") {
            let obj1 = TestMigrateVer0()
            obj1.name = "this is name"
            obj1.age = "16"
            obj1.email = "izouxv@gmail.com"
            context("add version 1 obj to db") {
               _=database.addObject(obj1)
            }
            
            var newVersion = 1
            context("migrate version 0->1") {
                SwiftyDb.MigrateAction(newVersion, database.dbPath, [TestMigrateVer1()])
                let res = database.objectsFor(TestMigrateVer1(), matchingFilter: ["name": obj1.name])
                
                expect(res.value?.count) == 1
                expect(res.value![0].age) == 16
            }
            
            newVersion = 2
            context("migrate version 1->2") {
                SwiftyDb.MigrateAction(newVersion, database.dbPath, [TestMigrateVer2()])
                
                let database = SwiftXDb(databaseName: "test_database")
                let res = database.objectsFor(TestMigrateVer2(), matchingFilter: ["name": obj1.name])
                
                expect(res.value?.count) == 1
                let item = res.value![0]
                expect(item.age) == 100
                expect(item.nikeName) == "default"
                expect(item.Address) == "Add"
            }
        }
    }
}

















