//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation

internal protocol MigrationOperationIX:MigrationOperationI{
    func commit()
    var operationCount : Int {get}
}

internal protocol OperateAction {
}

internal class OperationAdd : NSObject, OperateAction{
    var name : String
    init(_ name: String) {
        self.name = name
    }
}

internal class OperationRemove : NSObject, OperateAction{
    var name : String
    init(_ name: String) {
        self.name = name
    }
}

internal class OperationRename : NSObject, OperateAction{
    var name : String
    var newName : String
    init(_ name: String, _ newName: String) {
        self.name = name
        self.newName = newName
    }
}

internal class OperationMigrate : NSObject, OperateAction{
    var name : String
    var migrate : (SQLiteValue?) -> SQLiteValue?
    init(_ name: String, _ migrate: @escaping ((SQLiteValue?) -> SQLiteValue?)) {
        self.name = name
        self.migrate = migrate
    }
}
class TestClassSimple2:NSObject , Storable{
    var primaryKey: NSNumber = 1
    var num: Int      = 0
    
    required override init() {}
}

internal class MigrationPropertieOperation : NSObject, MigrationOperationIX{
    var db : SwiftyDb
    var operationCount : Int {
        return operQ.count
    }
    var tableType :  MigrationProperties
    var operQ : [OperateAction] = []
    init(_ swiftyDB : SwiftyDb, _ tableType : MigrationProperties) {
        self.db = swiftyDB
        self.tableType = tableType
    }
    func add(_ name: String)->MigrationOperationI{
        operQ.append(OperationAdd(name))
        return self
    }
    func remove(_ name: String)->MigrationOperationI{
        operQ.append(OperationRemove(name))
        return self
    }
    func rename(_ name: String,_ newName: String)->MigrationOperationI{
        operQ.append(OperationRename(name, newName))
        return self
    }
    public func migrate(_ newName: String, _ dataMigrate: @escaping ((SQLiteValue?) -> SQLiteValue?))->MigrationOperationI {
        operQ.append(OperationMigrate(newName,dataMigrate))
        return self
    }
    public func commit() {
        let tableName = tableType.tableName()
        if self.operQ.count==0{
            Swift.print("Warning!!! type: \(tableName) operQ is empty")
            return
        }
        
        var onlyHasAdd = true
        for item in self.operQ{
            if item is OperationAdd{
            }else{
                onlyHasAdd = false
                break
            }
        }
        
        let propertyData = PropertyData.validPropertyDataForObject(tableType)
        var attrMaps : [String: PropertyData] = [:]
        for item in propertyData{
            if let name = item.name{
                attrMaps[name] = item
            }
        }
        
        if onlyHasAdd{
            for itemx in self.operQ{
                let item = itemx as! OperationAdd
                let type = attrMaps[item.name]!.type!
                let sqlType = SQLiteDatatype(type:type)!
                db.query("ALTER TABLE \(tableName) ADD COLUMN \(item.name) \(sqlType.rawValue);")
            }
            return
        }
        
        // rename table
        let tmpTableName = "__"+tableType.tableName()
        db.query("ALTER TABLE \(tableName) RENAME TO \(tmpTableName);")
        
        // create new table
        _=db.createTableForTypeRepresentedByObject(tableType)
        
        //migrate
        let statement = "SELECT ALL * FROM \(tmpTableName)"
        db.query(statement, nil, {(stat:Statement)->Void in
            Swift.print("stat: \(stat.dictionary)")
            var data = stat.dictionary
            for itemx in self.operQ{
                if let item = itemx as? OperationMigrate{
                    let tmp = data[item.name]
                    data[item.name] = item.migrate(tmp!)
                }else if let item = itemx as? OperationRename{
                    if item.newName != item.name{
                        data[item.newName] = data[item.name]
                        data.removeValue(forKey: item.name)
                    }
                }else if let item = itemx as? OperationRemove{
                    data.removeValue(forKey: item.name)
                }else if let item = itemx as? OperationAdd{
                    if let type2 = attrMaps[item.name]{
                        //may be added name is removeed by next operation
                        let type = type2.type!
                        let sqlType = SQLiteDatatype(type:type)!
                        data[item.name] = sqlType.value()
                    }
                }
            }
            Swift.print("data: \(data)")
            let insertStatement = StatementGenerator.insertStatementForType(self.tableType, update: false)
            _=self.db.update(insertStatement, data)
        })
        
        //drop template table
        db.query("DROP TABLE \(tmpTableName);")
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
    internal static func tableInfos(_ dbPath : String, _ cb:@escaping(([String:sqlite_master], SwiftyDb)->Void)){
        let db = SwiftyDb(path:dbPath)
        try! db.open()
        defer {db.close()}
        
        let dataResults = db.objectsFor(sqlite_master(),matchingFilter:nil, false)
        Swift.print("result: \(dataResults)")
        
        var tables : [String:sqlite_master] = [:]
        
        if dataResults.isSuccess{
            for table in dataResults.value!{
                if table.isTable(){
                    tables[table.name] = table
                }
            }
        }
        cb(tables, db)
    }
    public static func MigrateCheck(_ versionNew : Int, _ dbPath : String, _ tables : [MigrationProperties])->Bool{
        var needMigrate = false
        self.tableInfos(dbPath, {(tables_sqlite: [String:sqlite_master],db: SwiftyDb) in
            let old_version = db.user_version
            for item in tables{
                if (tables_sqlite[item.tableName()] != nil){
                    let oper : MigrationOperationIX =  MigrationPropertieOperation(db, item)
                    type(of:item).Migrate(old_version,oper)
                    if oper.operationCount>0{
                        needMigrate = true
                        break
                    }
                }
            }
        })
        return needMigrate
    }
    public static func MigrateAction(_ versionNew : Int, _ dbPath : String, _ tables : [MigrationProperties]){
        self.tableInfos(dbPath, {(tables_sqlite: [String:sqlite_master],db: SwiftyDb) in
            let old_version = db.user_version
            db.foreign_keys = false
            _=db.transaction { (sdb:SwiftyDb) in
                for item in tables{
                    if (tables_sqlite[item.tableName()] != nil){
                        let oper : MigrationOperationIX =  MigrationPropertieOperation(sdb, item)
                        type(of:item).Migrate(old_version,oper)
                        oper.commit()
                    }
                }
            }
            db.foreign_keys = true
            db.user_version = versionNew
        })
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
















