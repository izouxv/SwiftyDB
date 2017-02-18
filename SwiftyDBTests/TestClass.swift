//
//  TestClass.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 10/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

@testable import SwiftyDB

class DynamicTestClass: NSObject {
    
    var primaryKey: NSNumber = 1
    
    var optionalString: String?
    var optionalNSString: NSString?
    
    var optionalDate: Date?
    var optionalNumber: NSNumber?
    var optionalData: Data?
    
    var optionalArray: NSArray?
    var optionalDictionary: NSDictionary?
    
    /* Not null properties */
    var string: String      = "string"
    var nsstring: NSString  = "nsstring"
    
    var date: Date        = Date()
    var number: NSNumber    = 1
    var data: Data        = String("Test").data(using: String.Encoding.utf8)! //Empty data is treated as NULL by sqlite3
    
    var int: Int            = 1
    var uint: UInt          = 1
    
    var bool: Bool          = false
    
    var float: Float        = 1
    var double: Double      = 1
    
    var array: NSArray = ["1","2"]
    var dictionary = ["1":1,"2":2]
    override required init() {
        super.init()
    }
}

extension DynamicTestClass: PrimaryKeys {
    static func primaryKeys() -> Set<String> {
        return ["primaryKey"]
    }
}

class TestClass:NSObject {
    
    
    
    var primaryKey: NSNumber = 1
    var ignored: Int = -1
    
    
    var optionalString: String?
    var optionalNSString: NSString?
    var optionalCharacter: Character?
    
    var optionalDate: Date?
    var optionalNumber: NSNumber?
    var optionalData: Data?
    
    var optionalInt: Int?
    var optionalInt8: Int8?
    var optionalInt16: Int16?
    var optionalInt32: Int32?
    var optionalInt64: Int64?
    var optionalUint: UInt?
    var optionalUint8: UInt8?
    var optionalUint16: UInt16?
    var optionalUint32: UInt32?
    var optionalUint64: UInt64?
    
    var optionalBool: Bool?
    
    var optionalFloat: Float?
    var optionalDouble: Double?
    
    /* Not null properties */
    var string: String      = "string"
    var character: Character = "c"
    var nsstring: NSString  = "nsstring"
    
    var date: Date        = Date()
    var number: NSNumber    = 1
    var data: Data        = String("Test").data(using: String.Encoding.utf8)! //Empty data is treated as NULL by sqlite3
    
    var int: Int            = 1
    var int8: Int8          = 1
    var int16: Int16        = 1
    var int32: Int32        = 1
    var int64: Int64        = 1
    var uint: UInt          = 1
    var uint8: UInt8        = 1
    var uint16: UInt16      = 1
    var uint32: UInt32      = 1
    var uint64: UInt64      = 1
    
    var bool: Bool          = false
    
    var float: Float        = 1
    var double: Double      = 1
    
    var array: NSArray = ["1","2"]
    var optionalArray: NSArray? = ["1","2"]
    var dictionary: NSDictionary = ["1":1,"2":2]
    var optionalDictionary: NSDictionary? = ["1":1,"2":2]
    
    required override init() {}
    
    
}

extension TestClass: PrimaryKeys {
    static func primaryKeys() -> Set<String> {
        return ["primaryKey"]
    }
}
extension TestClass: IgnoredProperties {
    static func ignoredProperties() -> Set<String> {
        return ["ignored"]
    }
}

class TestClassSimple:NSObject {
    var primaryKey: NSNumber = 1
    var num: Int      = 0
}

extension TestClassSimple: PrimaryKeys {
    static func primaryKeys() -> Set<String> {
        return ["primaryKey"]
    }
}

class TestMigrateVer0 : NSObject{
    var name : String = ""
    var age : String = ""
    var email : String = ""
    var ignored : String = ""
}
extension TestMigrateVer0: PrimaryKeys,IgnoredProperties,TableName {
    static func primaryKeys() -> Set<String> {
        return ["name"]
    }
    static func ignoredProperties() -> Set<String> {
        return ["ignored"]
    }
    static func tableName()->String{
        return "testMigrate"
    }
}

class TestMigrateVer1 : NSObject, MigrationProperties, TableName{
    var name : String = ""
    var age : Int = 0  //retype
    var address : String = ""//add
    //    var email : String = ""//remove
    static  func tableName()->String{
        return "testMigrate"
    }
    static func Migrate(_ verOld:Int, _ action:MigrationOperationI){
        if verOld < 1{
            _=action.remove("email")
                .migrate("age", { (oldData:SQLiteValue?) -> SQLiteValue? in
                    return Int(oldData as! String)
                })
                .add("address")//add new colume and set default data
                .migrate("address", { (oldData:SQLiteValue?) -> SQLiteValue? in
                    return "Add"
                })
        }
    }
}


class TestMigrateVer2 : NSObject, MigrationProperties, TableName{
    var name : String = ""
    var age : Int = 0//update data
    var Address : String = ""//rename
    var nikeName : String = ""//add and init
    static  func tableName()->String{
        return "testMigrate"
    }
    static func Migrate(_ verOld:Int, _ action:MigrationOperationI){
        if verOld < 2{
            _=action.rename("address", "Address")
                .migrate("age", { (oldData:SQLiteValue?) -> SQLiteValue? in//version upgrade, and data will updata
                    return 100
                })
                .add("nikeName")//add new colume and set default data
                .migrate("nikeName", { (oldData:SQLiteValue?) -> SQLiteValue? in
                    return "default"
                })
        }
    }
}


class TestMigrateVer0_2 : NSObject, MigrationProperties, TableName{
    var name : String = ""
    var age : Int = 0//update data
    var Address : String = ""//rename
    var nikeName : String = ""//add and init
    static  func tableName()->String{
        return "testMigrate"
    }
    static func Migrate(_ verOld:Int, _ action:MigrationOperationI){
        TestMigrateVer1.Migrate(verOld, action)
        TestMigrateVer2.Migrate(verOld, action)
    }
}





















