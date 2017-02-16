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
    func tableName()->String{
        if let sss = self as? TableNameSet{
            return (type(of:sss)).tableName()
        }
        let name = String(describing: type(of: self))
        return name
    }
}

public protocol TableNameSet {
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

public protocol SwiftDb{
    var dbPath : String{get}
    func open() throws
    func close()
    
    func key(_ key: String)throws
    func rekey(_ key: String)throws
    
    static func Migrate(_ versionNew : Int, _ dbPath : String, _ tables : [MigrationProperties])
    
    func sync(_ block: @escaping ((_ database: SwiftyDb) throws -> Void)) throws
    func transaction(_ block: @escaping ((_ db: SwiftyDb) throws -> Void)) ->Bool
    
    func addObject<S: Storable> (_ object: S, update: Bool) -> Result<Bool>
//    func addObjects<S: Storable> (_ object: S, _ moreObjects: S...) -> Result<Bool>
    func addObjects<S: Storable> (_ objects: [S], update: Bool) -> Result<Bool>
    func deleteObjectsForType (_ type: Storable, matchingFilter filter: Filter?) -> Result<Bool>
    func update(_ insertStatement: String, _ data: NamedSQLiteValues)-> Result<Bool>
    
    func query(_ sql: String, _ values: SQLiteValues?, _ cb:((Statement)->Void)?)
    func dataFor<S: Storable> (_ obj: S, matchingFilter filter: Filter? , _ checkTableExist:Bool) -> Result<[[String: Value?]]>
    func objectsFor<S> (_ obj: S, matchingFilter filter: Filter? , _ checkTableExist:Bool) -> Result<[S]> where S: Storable
}


//// TODO: Allow queues working on different databases at the same time
//private let _queue: dispatch_queue_t = dispatch_queue_create("TinySQLiteQueue", nil)

//需要继承NSObjec才会出现在SwiftDB－swift.h里面
open class SwiftyDb {
    //@nonobjc
    static let defaultDB : SwiftyDb = SwiftyDb.init(databaseName: "SwiftyDB")
    
    internal let queue: DispatchQueue = DispatchQueue(label: "swiftdb write or read queue", attributes: [])
    
    internal let database : DatabaseConnection
    
    /** A cache containing existing table names */
    internal var existingTables: Set<String> = []
    
    /** Create a database queue for the database at the provided path */
    public init(path: String) {
        database = DatabaseConnection(path: path)
    }
    deinit {
        self.close()
    }
}

extension SwiftyDb{
    public var dbPath : String{
        return database.path
    }
    public func open() throws {
        try self.database.open()
        self.query("PRAGMA journal_mode = WAL")
    }
    public func close(){
        try! self.database.close()
    }
    public convenience init(databaseName: String) {
        let documentsDir : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let  path = documentsDir+"/\(databaseName).sqlite"
        
        self.init(path:path)
        //  try! self.open()
    }
    public convenience init(userPath: String) {
        let  path1 = "\(userPath).sqlite"
        self.init(path:path1)
    }
}

extension SwiftyDb{
    public func key(_ key: String)throws{
        try self.database.key(key: key)
    }
    public func rekey(_ key: String)throws{
        try self.database.rekey(key: key)
    }
}









