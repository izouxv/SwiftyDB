//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation

internal protocol MigrationOperationIX:MigrationOperationI{
    func commit()
}

public protocol OperateAction {
    func action(_ db : SwiftyDb,_ table: MigrationProperties.Type)
}

internal class OperationAdd : NSObject, OperateAction{
    var name : String
    var type : SQLiteDatatypeTiny
    init(_ name: String, _ type: SQLiteDatatypeTiny) {
        self.name = name
        self.type = type
    }
    func action(_ db : SwiftyDb,_ table: MigrationProperties.Type){
        //ALTER TABLE OLD_COMPANY ADD COLUMN SEX char(1);
        db.query("ALTER TABLE OLD_COMPANY ADD COLUMN \(name) \(type.rawValue);")
    }
}

internal class OperationRemove : NSObject, OperateAction{
    var name : String
    init(_ name: String) {
        self.name = name
    }
    func action(_ db : SwiftyDb,_ table: MigrationProperties.Type){
        
    }
}
internal class OperationMigrate : NSObject, OperateAction{
    var name : String
    var type : SQLiteDatatypeTiny?
    var migrate : ((Any) -> Any)?
    init(_ name: String, _ type: SQLiteDatatypeTiny?, _ migrate: ((Any) -> Any)?) {
        self.name = name
        self.type = type
        self.migrate = migrate
    }
    func action(_ db : SwiftyDb,_ table: MigrationProperties.Type){
        //ALTER TABLE database_name.table_name RENAME TO new_table_name;
        //ALTER TABLE COMPANY RENAME TO OLD_COMPANY;
        //                    let statement = "SELECT ALL * FROM \(table.name)"
        //                    db.query(statement, nil, {(stat:Statement)->Void in
        //                        Swift.print("stat: \(stat.dictionary)")
        //                    })
    }
}



var dbMigrates : [MigrationProperties.Type] = []


internal class MigrationPropertiesOperation : NSObject, MigrationOperationIX{
    var db : SwiftyDb
    var tableType :  MigrationProperties.Type
    var operQ : [OperateAction] = []
    init(_ swiftyDB : SwiftyDb, _ tableType : MigrationProperties.Type) {
        self.db = swiftyDB
        self.tableType = tableType
    }
    func add(_ name: String,_ newType: SQLiteDatatypeTiny)->MigrationOperationI{
        operQ.append(OperationAdd(name, newType))
        return self
    }
    func remove(_ name: String)->MigrationOperationI{
        operQ.append(OperationRemove(name))
        return self
    }
    public func migrate(_ newName: String, _ newType: SQLiteDatatypeTiny?, _ dataMigrate: ((Any) -> Any)?)->MigrationOperationI {
        operQ.append(OperationMigrate(newName, newType,dataMigrate ))
        return self
    }
    public func commit() {
        db.foreign_keys = false
        _=db.transaction { (sdb:SwiftyDb) in
            for i in 0..<self.operQ.count{
                let item  = self.operQ[i]
                item.action(sdb, self.tableType)
            }
        }
        db.foreign_keys = true
    }
}


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

extension SwiftyDb {
    internal func tableNeedMigrate() ->Bool {
        return true
    }
    public class func Migrate(_ versionNew : Int, _ dbPath : String){
        let db = SwiftyDb(path:dbPath)
        try! db.open()
        defer {db.close()}
        
        let dataResults = db.objectsForType(sqlite_master(),matchingFilter:nil, false)
        Swift.print("result: \(dataResults)")
        
        let old_version = db.user_version
        if dataResults.isSuccess{
            for table in dataResults.value!{
                if table.isTable() && db.tableNeedMigrate(){
                    for item in dbMigrates{
                        let oper : MigrationOperationIX =  MigrationPropertiesOperation(db, item)
                        item.Migrate(old_version,oper)
                        oper.commit()
                    }
                }
            }
        }
        db.user_version = versionNew
    }
}
 

extension SwiftyDb {
    internal var foreign_keys : Bool{
        get{
            var foreign_keys : Bool = false
            self.query("PRAGMA foreign_keys", nil, {(stat:Statement)->Void in
                let fKey = stat.dictionary["foreign_keys"] as! String
                foreign_keys = fKey == "on"
            })
            return foreign_keys
        }
        set(value){
            let type = value ? "on" : "off"
            self.query("PRAGMA foreign_keys = \(type)")
        }
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



//https://www.techonthenet.com/sqlite/tables/alter_table.php
/*
 
 PRAGMA foreign_keys=off;
 
 BEGIN TRANSACTION;
 
 ALTER TABLE employees RENAME TO _employees_old;
 
 CREATE TABLE employees
 ( employee_id INTEGER PRIMARY KEY AUTOINCREMENT,
 last_name VARCHAR NOT NULL,
 first_name VARCHAR,
 hire_date DATE
 );
 
 INSERT INTO employees (employee_id, last_name, first_name, hire_date)
 SELECT employee_id, last_name, first_name, hire_date
 FROM _employees_old;
 
 COMMIT;
 
 PRAGMA foreign_keys=on;
 */



/*
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
 */















