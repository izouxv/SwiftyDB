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
            let obj1 = TestMigrateVer1()
            obj1.name = "this is name"
            obj1.age = "16"
            obj1.email = "izouxv@gmail.com"
            context("add version 1 obj to db") {
               _=database.addObject(obj1)
            }
            let newVersion = 100
            context("migrate model 1 to 2") {
                SwiftyDb.Migrate(newVersion, database.dbPath, [TestMigrateVer2()])
                let res = database.objectsFor(TestMigrateVer2(), matchingFilter: ["name": obj1.name])
                Swift.print("res: \(res.value?[0].description)")
                Swift.print("res: \(res.value?[0].description)")
            }
        }
    }
}

















