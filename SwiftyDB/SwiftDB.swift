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

/** Implement this protocol to ignore arbitrary properties */
public protocol MigrationProperties {
    static func migrationProperties(_ oldVersion : Int) -> Set<String>
}




/*
 all models' table info need save into db
 
 Nested Objects
 
 RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
 config.objectClasses = @[MyClass.class, MyOtherClass.class];
 RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:nil];
 
 
 Linear Migrations
 Suppose we have two users for our app: JP and Tim. JP updates the app very often, but Tim happens to skip a few versions. It’s likely that JP has seen every new version of our app, and every schema upgrade in order: he downloaded a version of the app that took him from v0 to v1, and later another update that took him from v1 to v2. In contrast, it’s possible that Tim might download an update of the app that will need to take him from v0 to v2 immediately. Structuring your migration blocks with non-nested if (oldSchemaVersion < X) calls ensures that they will see all necessary upgrades, no matter which schema version they start from.
 
 Another scenario may arise in the case of users who skipped versions of your app. If you delete a property email at version 2 and re-introduce it at version 3, and a user jumps from version 1 to version 3, Realm will not be able to automatically detect the deletion of the email property, as there will be no mismatch between the schema on disk and the schema in the code for that property. This will lead to Tim’s Person object having a v3 address property that has the contents of the v1 address property. This may not be a problem, unless you changed the internal storage representation of that property between v1 and v3 (say, went from an ISO address representation to a custom one). To avoid this, we recommend you nil out the email property on the if (oldSchemaVersion < 3) statement, guaranteeing that all Realms upgraded to version 3 will have a correct dataset.
 
 */



//// TODO: Allow queues working on different databases at the same time
//private let _queue: dispatch_queue_t = dispatch_queue_create("TinySQLiteQueue", nil)

//需要继承NSObjec才会出现在SwiftDB－swift.h里面
open class SwiftyDb {
    //@nonobjc
    static let defaultDB : SwiftyDb = SwiftyDb.init(databaseName: "SwiftyDB")
    
    internal let queue: DispatchQueue = DispatchQueue(label: "TinySQLiteQueue", attributes: [])
    
    internal let database:       DatabaseConnection
    
    /** Create a database queue for the database at the provided path */
    public init(path: String) {
        database = DatabaseConnection(path: path)
    }
    
    /** A cache containing existing table names */
    internal var existingTables: Set<String> = []
    
    public func open() throws {
        try self.database.open()
    }
    
    public func close(){
        try! self.database.close()
    }
    
    deinit {
        self.close()
    }
    
    public convenience init(databaseName: String) {
        let documentsDir : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let  path1 = documentsDir+"/\(databaseName).sqlite"
        
        self.init(path:path1)
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









