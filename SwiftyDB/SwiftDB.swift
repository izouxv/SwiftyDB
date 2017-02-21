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


public protocol Filter{
    func equal(_ propertyName: String, value: Value?) -> Filter
    func lessThan(_ propertyName: String, value: Value?) -> Filter
    func lessOrEqual(_ propertyName: String, value: Value?) -> Filter
    func greaterThan(_ propertyName: String, value: Value?) -> Filter
    func greaterOrEqual(_ propertyName: String, value: Value?) -> Filter
    func notEqual(_ propertyName: String, value: Value?) -> Filter
    func contains(_ propertyName: String, array: [Value?]) -> Filter
    func notContains(_ propertyName: String, array: [Value?]) -> Filter
    func like(_ propertyName: String, pattern: String) -> Filter
    func notLike(_ propertyName: String, pattern: String) -> Filter
    func orderBy(_ propertyNames: [String]) -> Filter
    func limit(_ limit: Int) -> Filter
    func offset(_ offset: Int) -> Filter
    
    func delete()->Result<Bool>
    func get()->Result<[[String: Value?]]>
//    func update()->Result<Bool> 
//    func count()->Result<Bool> //count,avg,max,min,sum,total
    
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
    
    func transaction(_ block: @escaping ((_ db: SwiftyDb) throws -> Void)) ->Bool
    
    func addObject<S: Storable> (_ object: S,_ update: Bool) -> Result<Bool>
    func addObjects<S: Storable> (_ objects: [S],_ update: Bool) -> Result<Bool>
    func update(_ sql: String, _ data: SqlValues?)-> Result<Bool>
    func query(_ sql: String, _ values: SqlValues?, _ cb:((StatementData)->Void)?)
    
    func deleteObjectsForType (_ type: Storable,_ filter: Filter?) -> Result<Bool>
    func dataFor<S: Storable> (_ obj: S,_ filter: Filter? , _ checkTableExist:Bool) -> Result<[[String: Value?]]>
    func objectsFor<S> (_ obj: S,_ filter: Filter? , _ checkTableExist:Bool) -> Result<[S]> where S: Storable
    
    func with(_ obj: Storable)->Filter 
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


//// TODO: Allow queues working on different databases at the same time
//private let _queue: dispatch_queue_t = dispatch_queue_create("TinySQLiteQueue", nil)

//需要继承NSObjec才会出现在SwiftDB－swift.h里面
internal class swiftyDb : SwiftyDb {
    //@nonobjc
    static let defaultDB : swiftyDb = swiftyDb.init(databaseName: "SwiftyDB")
    
    internal let queue: DispatchQueue = DispatchQueue(label: "swiftdb write or read queue", attributes: [])
    
    internal let database : DatabaseConnection
    
    /** A cache containing existing table names */
    internal var existingTables: Set<String> = []
    
    /** Create a database queue for the database at the provided path */
    public init(absPath: String) {
        database = DatabaseConnection(path: absPath)
    }
    public convenience init(databaseName: String) {
        let documentsDir : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let  path = documentsDir+"/\(databaseName).sqlite"
        
        self.init(absPath:path)
        //  try! self.open()
    }
    public convenience init(userPath: String) {
        let  path1 = "\(userPath).sqlite"
        self.init(absPath:path1)
    }
    deinit {
        self.close()
    }
}



extension swiftyDb{
    public var path : String{
        return database.path
    }
    public func open() throws {
        try self.database.open()
        self.query("PRAGMA journal_mode = WAL")
    }
    public func close(){
        try! self.database.close()
    }
    
}

extension swiftyDb{
    public func key(_ key: String)throws{
        try self.database.key(key: key)
    }
    public func rekey(_ key: String)throws{
        try self.database.rekey(key: key)
    }
}









