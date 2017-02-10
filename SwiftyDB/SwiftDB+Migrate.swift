//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation



//CREATE TABLE sqlite_master (
//    type TEXT,
//    name TEXT,
//    tbl_name TEXT,
//    rootpage INTEGER,
//    sql TEXT
//);
internal class sqlite_master : NSObject, Storable{
    public var type: String = "table"//table, index
    public var name: String = ""
    public var tbl_name: String = ""
    public var rootpage: UInt64 = 1
    public var sql: String?//table has sql, auto make index has no sql. mannel index has sql
    required override init() {
        super.init()
    }
}

extension SwiftyDb {
    public class func Migrate(_ dbPath : String){
        let db = SwiftyDb(path:dbPath)
        try! db.open()
        defer {db.close()}
        let dataResults = db.objectsForType(sqlite_master(),matchingFilter:nil, false)
  
        Swift.print("result: \(dataResults)")
    }
    
    //数据交换
    //new data is nil, : delete this data
    internal class func DataUpgrade(_ ver:Int, _ talbeName : String, _ oldData:[String:Any])->[String:Any]?{
        return oldData
    }
}





