//
//  DatabaseManipulationSpec.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 13/01/16.
//

@testable import SwiftyDB
import Quick
import Nimble

class DatabaseManipulationSpec: SwiftyDBSpec {
    
    override func spec() {
        super.spec()
        
        let database = SwiftXDb(databaseName: "test_database")
       // defer database.close()
        
        describe("Data in database is updated") {
            let object = TestClass()
            object.primaryKey = 123
            object.string = "First string"
            
           // SwiftyDB.addObject(adsf)
            let filter: SwiftyDB.Filter = ["primaryKey": object.primaryKey]
            
            context("object is added") {
                it("should contain the object after it is added") {
                    expect(database.addObject(object).isSuccess).to(beTrue())
                    expect(database.dataFor(TestClass(), filter).value?.count) == 1
                }
            }
            
            context("object is deleted") {
                it("should not contain the object after deletion") {
                    expect(database.deleteObjectsForType(TestClass(), filter).isSuccess).to(beTrue())
                    expect(database.dataFor(TestClass(), filter).value?.count) == 0
                }
            }
            
            context("object is updated") {
                it("should update existing objects") {
                    database.addObject(object)
                    
                    object.string = "Updated string"
                    
                    expect(database.addObject(object).isSuccess).to(beTrue())
                    expect(database.dataFor(TestClass(), filter).value?.count) == 1
                    
                    if let stringValue = database.dataFor(TestClass(), filter).value?.first?["string"] as? String {
                        expect(stringValue == "Updated string").to(beTrue())
                    }
                }
            }
            
            context("object is not updated if it should not") {
                it("should fail to add same object twice") {
                    database.addObject(object)
                    expect(database.addObject(object, false).isSuccess).to(beFalse())
                }
            }
        }
    }
}
