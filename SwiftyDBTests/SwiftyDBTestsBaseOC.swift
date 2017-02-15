//
//  SwiftDBTests.swift
//  SwiftDBTests
//
//  Created by zouxu on 3/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//

import XCTest
@testable import SwiftyDB



class DogOC:DBBase {
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
extension DogOC: PrimaryKeys {
    class func primaryKeys() -> Set<String> {
        return ["id"]
    }
}
extension DogOC: IgnoredProperties {
    class func ignoredProperties() -> Set<String> {
        return ["owner"]
    }
}




class SwiftDBTestsOC: XCTestCase {
    
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
        
        let dog1 = DogOC.init(1, "dog1")
        dog1.baseName = "baseName"
        let database = SwiftXDb(databaseName: "dogdsskk2rrb2122_1")
        
        try! database.key("123123")
        let dogs  : [NSObject] = [dog1]
        XCTAssertTrue(database.addObjects(dogs, update: true).isSuccess)
        XCTAssertTrue(database.dataFor(DogOC()).value?.count == 1)
    }
    
}
