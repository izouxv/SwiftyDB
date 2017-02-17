//
//  FilterSpec.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 17/01/16.
//

import Quick
import Nimble
@testable import SwiftyDB


class FilterSpec: SwiftyDBSpec {
    
    func resetDatabase(_ database: swiftyDb) {
        let object = TestClass()
        _=database.deleteObjectsForType(TestClass())
        object.primaryKey = 1
        _=database.addObject(object)
        object.primaryKey = 2
        _=database.addObject(object)
        object.primaryKey = 3
        _=database.addObject(object)
    }
    
    override func spec() {
        
        describe("Filter results") {
            
            context("retrieve object") {
                
                let database = SwiftXDb(databaseName: "test_database")
          
                
                func countForFilter(_ filter: SwiftyDB.Filter) -> Int {
                    return database.dataFor(TestClass(), matchingFilter: filter).value!.count
                }
                
                it("should filter equal") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(["primaryKey": 2])) == 1
                    expect(countForFilter(["primaryKey": "dsa"])) == 0
                }
                
                it("should filter not equal") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.notEqual("primaryKey", value: 3))) == 2
                    expect(countForFilter(Filter.notEqual("primaryKey", value: 4))) == 3
                }
                
                it("should filter less") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.lessThan("primaryKey", value: 3))) == 2
                    expect(countForFilter(Filter.lessThan("primaryKey", value: 1))) == 0
                }
                
                it("should filter less or equal") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.lessOrEqual("primaryKey", value: 3))) == 3
                    expect(countForFilter(Filter.lessOrEqual("primaryKey", value: 1))) == 1
                }
                
                it("should filter greater") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.greaterThan("primaryKey", value: 3))) == 0
                    expect(countForFilter(Filter.greaterThan("primaryKey", value: 1))) == 2
                }
                
                it("should filter greater or equal") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.greaterOrEqual("primaryKey", value: 3))) == 1
                    expect(countForFilter(Filter.greaterOrEqual("primaryKey", value: 1))) == 3
                }
                
                it("should filter contains") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.contains("primaryKey", array: [1,2,3]))) == 3
                    expect(countForFilter(Filter.contains("primaryKey", array: [1]))) == 1
                }
                
                it("should filter not contains") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.notContains("primaryKey", array: [1,2,3]))) == 0
                    expect(countForFilter(Filter.notContains("primaryKey", array: [1]))) == 2
                }
                
                it("should filter like") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.like("primaryKey", pattern: "4"))) == 0
                    expect(countForFilter(Filter.like("primaryKey", pattern: "1"))) == 1
                }
                
                it("should filter not like") {
                    self.resetDatabase(database)
                    
                    expect(countForFilter(Filter.notLike("primaryKey", pattern: "4"))) == 3
                    expect(countForFilter(Filter.notLike("primaryKey", pattern: "1"))) == 2
                }
            }
        }
    }
}
