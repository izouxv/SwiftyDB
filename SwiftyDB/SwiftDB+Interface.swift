//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation


/** All objects in the database must conform to the 'Storable' protocol */
public protocol Storable {
    /** Used to initialize an object to get information about its properties */
    init()
    func setValuesForKeys(_ keyedValues: [String : Any])
    func value(forKey key: String) -> Any?
}

extension Storable {
    internal func tableName()->String{
        if let sss = self as? TableName{
            return (type(of:sss)).tableName()
        }
        let name = String(describing: type(of: self))
        return name
    }
}

public protocol TableName {
    static func tableName()->String
}

/** Implement this protocol to use primary keys */
public protocol PrimaryKeys {
    static func primaryKeys() -> Set<String>
}

/** Implement this protocol to ignore arbitrary properties */
public protocol IgnoredProperties {
    static func ignoredProperties() -> Set<String>
}

/** Implement this protocol to ignore arbitrary properties */
public protocol IndexProperties {
    static func indexProperties() -> Set<String>
}

public protocol MigrationOperationI{
    func add(_ name: String)->MigrationOperationI
    func remove(_ name: String)->MigrationOperationI
    func rename(_ name: String,_ newName: String)->MigrationOperationI
    func migrate(_ name: String,_ dataMigrate:@escaping((_ data: SQLiteValue?)->SQLiteValue?))->MigrationOperationI
}

public protocol MigrationProperties : Storable{
    static func Migrate(_ verOld:Int, _ action:MigrationOperationI)
}

public protocol SwiftyDb{
    
    var path : String{get}
    func open() throws
    func close()
    
    func key(_ key: String)throws
    func rekey(_ key: String)throws
    
    //Migrate first : Check, second : Action
    func MigrateCheck(_ versionNew : Int, _ tables : [MigrationProperties])->Bool
    func MigrateAction(_ versionNew : Int, _ tables : [MigrationProperties])
    
    //can nested
//    func transaction(_ block:@escaping ((SwiftyDb, _:inout Bool) throws -> Void)) ->Bool
//    func transaction(_ block: @escaping ((SwiftyDb, _:inout Bool) throws -> Void)) ->Bool
    func transaction(_ block: @escaping (( _ db: SwiftyDb, _ rollback: inout Bool) throws -> Void)) ->Bool
    
    func addObject<S: Storable> (_ object: S,_ update: Bool) -> Result<Bool>
    func addObjects<S: Storable> (_ objects: [S],_ update: Bool) -> Result<Bool>
    func update(_ sql: String, _ data: SqlValues?)-> Result<Bool>
    func query(_ sql: String, _ values: SqlValues?, _ cb:((StatementData)->Void)?)
    
    func deleteObjectsForType (_ type: Storable,_ filter: Filter?) -> Result<Bool>
    func dataFor<S: Storable> (_ obj: S,_ filter: Filter? , _ checkTableExist:Bool) -> Result<[[String: Value?]]>
    func objectsFor<S> (_ obj: S,_ filter: Filter? , _ checkTableExist:Bool) -> Result<[S]> where S: Storable
    
//    func with(_ obj: Storable)->Filter 
}


public func SwiftyDb_Init(absPath: String)->SwiftyDb{
    return swiftyDb(absPath:absPath)
}
public func SwiftyDb_Init(databaseName: String)->SwiftyDb{
    return swiftyDb(databaseName:databaseName)
}
public func SwiftyDb_Init(userPath: String)->SwiftyDb{
    return swiftyDb(userPath:userPath)
}









