//
//  SwiftDBTests.swift
//  SwiftDBTests
//
//  Created by zouxu on 3/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//

import XCTest
@testable import SwiftyDB

class Dog:NSObject, Storable {
    var id: Int?
    var name: String?
    var owner: String?
    var birth: NSDate?
    
    required override init() {}
}
extension Dog: PrimaryKeys {
    class func primaryKeys() -> Set<String> {
        return ["id"]
    }
}
extension Dog: IgnoredProperties {
    class func ignoredProperties() -> Set<String> {
        return ["name"]
    }
}



class SwiftDBTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let dog = Dog()
        let dogs = [dog]
        
        let database = SwiftyDB(databaseName: "dogtopia")
        database.addObject(dog, update: true)
        database.addObjects(dogs, update: true)
        /* Array of dictionaries representing `Dog` objects from the database */
        database.dataForType(Dog.self)
        database.dataForType(Dog.self, matchingFilter: ["id": 1])
        
      //  database.objectsForType(Dog.self)
       // database.objectsForType(Dog.self, matchingFilters:["id": 1])
        
        
        database.deleteObjectsForType(Dog.self)
    //   database.deleteObjectsForType(Dog.self, matchingFilters: ["name": "Max"])

        
        database.asyncAddObject(dog) { (result) -> Void in
            if let error = result.error {
                // Handle error
            }
        }
        
        
        database.asyncDataForType(Dog.self) { (result) -> Void in
            if let data = result.value {
                // Process data
            }
        }
        
        database.asyncDeleteObjectsForType(Dog.self) { (result) -> Void in
            if let error = result.error {
                // Handle error
            }
        }
        
        
        let filter = Filter.equal("name", value: "Ghost")
            .like("owner", pattern: "J_h%")
            .greaterThan("id", value: 3)
        
     //   database.objectsForType(Dog.self, matchingFilter: filter)
    //    database.objectsForType(Dog.self, matchingFilter:filter)
        
        
//        switch result {
//        case .Success(let value):
//        // Process value
//        case .Error(let error):
//            // Handle error
//        }
        
        
        
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
