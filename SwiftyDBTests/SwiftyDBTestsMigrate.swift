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

class SwiftyDbMigrate: SwiftyDBSpec {
    override func spec() {
        super.spec()
        let database = SwiftyDbX(databaseName: "test_database")
        describe("Data in database is updated") {
            context("object added test sample data") {
                let dbPath = "/Users/zouxu/Desktop/test_database.sqlite"
                SwiftyDb.Migrate(dbPath)
            }
        }
    }
}

















