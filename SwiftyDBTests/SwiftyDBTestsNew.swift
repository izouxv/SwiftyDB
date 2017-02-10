//
//  SwiftDBTests.swift
//  SwiftDBTests
//
//  Created by zouxu on 3/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//

import XCTest
@testable import SwiftyDB



class Dog:NSObject {
    var id: Int
    var name: String
    var owner: String?
    var birth: NSDate?
    
    //required override init() {}
    init(_ id : Int, _ name: String) {
        self.id = id
        self.name = name
    }
    required override init(){
        self.id = 0
        self.name = "na"
    }
    override func setValuesForKeys(_ keyedValues: [String : Any]){
        super.setValuesForKeys(keyedValues)
    }
}
extension Dog: PrimaryKeys {
    class func primaryKeys() -> Set<String> {
        return ["id"]
    }
}
extension Dog: IgnoredProperties {
    class func ignoredProperties() -> Set<String> {
        return ["owner"]
    }
}

class BigDog:Dog {
    var XiXi: String = "XiXi"
}


class BigDogOC:Dog {
    var XiXi: String = "XiXi"
}


extension NSObject: Storable  {
}

class SwiftDBTestsNew: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
     
    func testWaOverride() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let dog1 = BigDog.init(1, "dog1")
        let database = SwiftyDbX(databaseName: "dogdsskk2rrb2122_1")
 
        try! database.key("123123")
        let dogs  : [NSObject] = [dog1]
        XCTAssertTrue(database.addObjects(dogs, update: true).isSuccess)
        XCTAssertTrue(database.dataForType(BigDog()).value?.count == 1)
    }
    
    func testWithDogNSObject() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let dog1 = Dog.init(1, "dog1")
        let database = SwiftyDbX(databaseName: "dogdkk2b2122_1")
 
        try! database.key("123123")
        let dogs  : [NSObject] = [dog1]
        XCTAssertTrue(database.addObjects(dogs, update: true).isSuccess)
        XCTAssertTrue(database.dataForType(Dog()).value?.count == 1)
    }
    
    func testWithDogType() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let dog1 = Dog.init(1, "dog1")
        let dog2 = Dog.init(2, "dog2")
        let dog3 = Dog.init(3, "dog3")
        let dogs = [dog3, dog2]
        
        let database = SwiftyDbX(databaseName: "dogdb")
  
        try! database.key("123123")
        
        XCTAssertTrue(database.addObject(dog1, update: true).isSuccess)
        XCTAssertTrue(database.dataForType(Dog()).value?.count == 1)
        XCTAssertTrue(database.addObjects(dogs, update: true).isSuccess)
        XCTAssertTrue(database.dataForType(Dog()).value?.count == 3)
        XCTAssertTrue(database.dataForType(Dog(), matchingFilter: ["id": 1]).value?.count == 1)
        
        dog2.name = "dog222"
        XCTAssertTrue(database.addObject(dog2, update: true).isSuccess)
   
        XCTAssertTrue(database.deleteObjectsForType(Dog(), matchingFilter: ["name": "dog1"]).isSuccess)
       
        let result = database.dataForType(Dog(), matchingFilter: ["id": 2])
        XCTAssertTrue(result.value![0]["name"] as! String == dog2.name)
         XCTAssertTrue( database.deleteObjectsForType(Dog()).isSuccess)
    }
 
    
}
