//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation




//// TODO: Allow queues working on different databases at the same time
//private let _queue: dispatch_queue_t = dispatch_queue_create("TinySQLiteQueue", nil)

//需要继承NSObjec才会出现在SwiftDB－swift.h里面
internal class swiftyDb : SwiftyDb {
    //@nonobjc
    static let defaultDB : swiftyDb = swiftyDb.init(databaseName: "SwiftyDB")
    
    /** A cache containing existing table names */
    internal var existingTables: Set<String> = []
    
    internal let queue: DispatchQueue = DispatchQueue(label: "swiftdb write or read queue", attributes: [])
    
    internal let database : DatabaseConnection
    
    internal var transactioning : Bool{//one trancation in same db queue
        return false
    }
    
    internal init(database : DatabaseConnection){
        self.database = database
    }
    /** Create a database queue for the database at the provided path */
    public convenience init(absPath: String) {
        let db = DatabaseConnection(path: absPath)
        self.init(database:db)
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











