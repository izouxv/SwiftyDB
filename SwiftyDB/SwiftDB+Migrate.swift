//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation


//https://sqlite.org/faq.html
//For indices, type is equal to 'index', name is the name of the index and tbl_name is the name of the table to which the index belongs. For both tables and indices, the sql field is the text of the original CREATE TABLE or CREATE INDEX statement that created the table or index. For automatically created indices (used to implement the PRIMARY KEY or UNIQUE constraints) the sql field is NULL.

//The SQLITE_MASTER table is read-only. You cannot change this table using UPDATE, INSERT, or DELETE. The table is automatically updated by CREATE TABLE, CREATE INDEX, DROP TABLE, and DROP INDEX commands.

//Temporary tables do not appear in the SQLITE_MASTER table. Temporary tables and their indices and triggers occur in another special table named SQLITE_TEMP_MASTER. SQLITE_TEMP_MASTER works just like SQLITE_MASTER except that it is only visible to the application that created the temporary tables. To get a list of all tables, both permanent and temporary, one can use a command similar to the following:
//
//BEGIN TRANSACTION;
//CREATE TEMPORARY TABLE t1_backup(a,b);
//INSERT INTO t1_backup SELECT a,b FROM t1;
//DROP TABLE t1;
//CREATE TABLE t1(a,b);
//INSERT INTO t1 SELECT a,b FROM t1_backup;
//DROP TABLE t1_backup;
//COMMIT;
//
//CREATE TABLE sqlite_master (
//    type TEXT,
//    name TEXT,
//    tbl_name TEXT,
//    rootpage INTEGER,
//    sql TEXT
//);
internal class sqlite_master : NSObject, Storable{
    public var type: String = "table"//table, index
    public var name: String = "Dog"
    public var tbl_name: String = "Dog"
    public var rootpage: UInt64 = 1
    //CREATE TABLE Dog (id INTEGER NOT NULL, name TEXT NOT NULL, PRIMARY KEY (id))
    public var sql: String?//table has sql, auto make index has no sql. mannel index has sql
    required override init() {
        super.init()
    }
    func isTable()->Bool{
        return self.type == "table"
    }
}


let KVersion  = 123456789
typealias migragteClosure = (_ ver:Int,_ tableName:sqlite_master,_ datas:[String:Any])->(Int,sqlite_master,[String:Any])
var dbMigrates : [migragteClosure] = []

extension SwiftyDb {
    internal class func MigrateAction(){
        let item1 : migragteClosure = {(_  ver: Int,_ tableName:sqlite_master,_ data:[String:Any])->(Int,sqlite_master,[String:Any]) in
            if tableName.name == "Dog"{
                if ver<=0{
                }
                if ver<=1{
                }
                if ver<=2{
                }
                if ver<=3{
                }
            }
            return (ver, tableName, data)
        }
        dbMigrates.append(item1)
    }
}
extension SwiftyDb {
    internal func tableNeedMigrate() ->Bool {
        return true
    }
    public class func Migrate(_ versionNew : Int, _ dbPath : String){
        let db = SwiftyDb(path:dbPath)
        try! db.open()
        defer {db.close()}
        
        let ver = db.user_version
        
//        Swift.print("version: \(db.user_version)")
//        db.user_version = 123456
//        Swift.print("version: \(db.user_version)")
//        db.query("PRAGMA journal_mode = WAL")
        
        let dataResults = db.objectsForType(sqlite_master(),matchingFilter:nil, false)
        Swift.print("result: \(dataResults)")
        
        if dataResults.isSuccess{
            for table in dataResults.value!{
                if table.isTable() && db.tableNeedMigrate(){
                    let statement = "SELECT ALL * FROM \(table.name)"
                    db.query(statement, nil, {(stat:Statement)->Void in
                        Swift.print("stat: \(stat.dictionary)")
                        for item in dbMigrates{
                            let (verNew, tableNew, dataNew) = item(ver, table, stat.dictionary)
                        }
                    })
                }
            }
        }
        
        db.user_version = versionNew
    }
}

extension SwiftyDb {
    internal var user_version : Int{
        get{
            var version : Int = 0
            self.query("PRAGMA user_version", nil, {(stat:Statement)->Void in
                version = stat.dictionary["user_version"] as! Int
            })
            return version
        }
        set(value){
            self.query("PRAGMA user_version = \(value)")
        }
    }
}

























