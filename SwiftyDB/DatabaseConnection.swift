//
//  DatabaseConnection.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 25/12/15.
//

import sqlite3

//import

// MARK: - Setup SQLiteValue protocol for all supported  datatypes

/** Valid SQLite types are marked using the 'SQLiteValue' protocol */
public protocol SQLiteValue {}

extension String: SQLiteValue {}
extension NSString: SQLiteValue {}
extension Character: SQLiteValue {}

extension Bool: SQLiteValue {}

extension Int: SQLiteValue {}
extension Int8: SQLiteValue {}
extension Int16: SQLiteValue {}
extension Int32: SQLiteValue {}
extension Int64: SQLiteValue {}
extension UInt: SQLiteValue {}
extension UInt8: SQLiteValue {}
extension UInt16: SQLiteValue {}
extension UInt32: SQLiteValue {}
extension UInt64: SQLiteValue {}

extension Float: SQLiteValue {}
extension Double: SQLiteValue {}

extension Data: SQLiteValue {}
extension Date: SQLiteValue {}
extension NSNumber: SQLiteValue {}

public typealias SQLiteValues = Array<SQLiteValue?>
public typealias NamedSQLiteValues = Dictionary<String, SQLiteValue?>

// MARK: -

public enum SQLError: Int32, Error, CustomStringConvertible {
    case ok                 = 0
    case error
    case internalError
    case permissionDenied
    case abort
    case busy
    case tableLocked
    case noMemory
    case readOnly
    case interrupted
    case ioError
    case corrupted
    case notFound
    case full
    case cannotOpen
    case lockProtocol
    case empty
    case schema
    case tooBig
    case constraintViolation
    case datatypeMismatch
    case libraryMisuse
    case noLSF
    case authorization
    case invalidFormat
    case outOfRange
    case notADatabase
    case notification
    case warning
    case row                = 100
    case done               = 101
    case bindingType
    case numberOfBindings
    
    public var description: String {
        return "TinySQLite.Error: \(self.message) (\(rawValue))"
    }
    
    public var message: String {
        switch self {
        case .ok:
            return "Successful result"
        case .error:
            return "SQL error or missing database"
        case .internalError:
            return "Internal logic error in SQLite"
        case .permissionDenied:
            return "Access permission denied"
        case .abort:
            return "Callback routine requested an abort"
        case .busy:
            return "The database file is locked"
        case .tableLocked:
            return "A table in the database is locked"
        case .noMemory:
            return "A malloc() failed"
        case .readOnly:
            return "Attempt to write a readonly database"
        case .interrupted:
            return "Operation terminated by sqlite3_interrupt()"
        case .ioError:
            return "Some kind of disk I/O error occurred"
        case .corrupted:
            return "The database disk image is malformed"
        case .notFound:
            return "Unknown opcode in sqlite3_file_control()"
        case .full:
            return "Insertion failed because database is full"
        case .cannotOpen:
            return "Unable to open the database file"
        case .lockProtocol:
            return "Database lock protocol error"
        case .empty:
            return "Database is empty"
        case .schema:
            return "The database schema changed"
        case .tooBig:
            return "String or BLOB exceeds size limit"
        case .constraintViolation:
            return "Abort due to constraint violation"
        case .datatypeMismatch:
            return "Data type mismatch"
        case .libraryMisuse:
            return "Library used incorrectly"
        case .noLSF:
            return "Uses OS features not supported on host"
        case .authorization:
            return "Authorization denied"
        case .invalidFormat:
            return "Auxiliary database format error"
        case .outOfRange:
            return "2nd parameter to sqlite3_bind out of range"
        case .notADatabase:
            return "File opened that is not a database file"
        case .notification:
            return "Notifications from sqlite3_log()"
        case .warning:
            return "Warnings from sqlite3_log()"
        case .row:
            return "sqlite3_step() has another row ready"
        case .done:
            return "sqlite3_step() has finished executing"
        case .bindingType:
            return "Tried to bind an unrecognized data type, or an NSNumber wrapping an unrecognied type"
        case .numberOfBindings:
            return "Incorrect number of bindings"
            
        }
    }
}

internal struct SQLiteResultHandler {
    static let successCodes: Set<Int32> = [SQLITE_OK, SQLITE_DONE, SQLITE_ROW]
    
    static func isSuccess(_ resultCode: Int32) -> Bool {
        return SQLiteResultHandler.successCodes.contains(resultCode)
    }
    
    static func verifyResultCode(_ resultCode: Int32, forHandle handle: OpaquePointer?) throws {
        guard isSuccess(resultCode) else {
            throw SQLError(rawValue: resultCode)!
        }
    }
}

// MARK: -

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)


/** Responsible for opening and closing database connections, executing queries, and managing transactions */
class DatabaseConnection {
    
    fileprivate var handle: OpaquePointer? = nil
    fileprivate let path: String
    
    fileprivate var isOpen: Bool = false
    
    internal func IsOpen() -> Bool {
        return self.isOpen
    }
    
    internal init(path: String) {
        self.path = path
    }
    
    deinit{
        try! self.close()
    }
    
    /** Open the database connection */
    internal func open() throws {
        if isOpen{
            return
        }
        try SQLiteResultHandler.verifyResultCode(sqlite3_open(path, &handle), forHandle: handle)
        isOpen = true
    }
    
    /** Close the database connection */
    internal func close() throws {
        if !isOpen{
            return
        }
        try SQLiteResultHandler.verifyResultCode(sqlite3_close(handle), forHandle: handle)
        handle = nil
        isOpen = false
    }
    
    /**
     Prepare a statement for the provided query
     
     - parameter query:  an SQLite query
     
     - returns:          a prepared statement
     */
    internal func prepare(_ query: String) throws -> Statement {
        let statement: Statement = Statement(query)
        try statement.prepareForDatabase(handle!)
        return statement
    }
}

// MARK: - Transactions
extension DatabaseConnection {
    
    /** Begin a transaction */
    internal  func beginTransaction() throws {
        try self.prepare("BEGIN TRANSACTION")
            .executeUpdate()
            .finalize()
    }
    
    /** End an ongoing transaction */
    internal  func endTransaction() throws {
        try self.prepare("END TRANSACTION")
            .executeUpdate()
            .finalize()
    }
    
    /** Rollback a transaction */
    internal func rollback() throws {
        try self.prepare("ROLLBACK TRANSACTION")
            .executeUpdate()
            .finalize()
    }
}

// MARK: - General
extension DatabaseConnection {
    
    /** Number of rows affected by INSERT, UPDATE, or DELETE since the database was opened */
    internal func changes() -> Int {
        return Int(sqlite3_changes(handle))
    }
    
    /** Total number of rows affected by INSERT, UPDATE, or DELETE since the database was opened */
    internal func totalChanges() -> Int {
        return Int(sqlite3_total_changes(handle))
    }
    
    /** Interrupts any pending database operations */
    internal func interrupt() {
        sqlite3_interrupt(handle)
    }
}

// MARK: - Convenience
extension DatabaseConnection {
    
    /**
     Check if a table exists
     
     - parameter tableName:  name of the table
     
     - returns:              boolean indicating whether the table exists, or not
     */
    internal func containsTable(_ tableName: String) throws -> Bool {
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
        
        let statement = try prepare(query)
            .execute([tableName])
        
        /* Finalize the statement if necessary */
        defer {
            try! statement.finalize()
        }
        
        return statement.next() != nil
    }
}


extension DatabaseConnection {
    #if SQLITE_HAS_CODEC
    internal func key(key: String) throws {
        try SQLiteResultHandler.verifyResultCode(sqlite3_key(handle, key, Int32(key.utf8.count)), forHandle: handle)
    }
    internal func rekey(key: String) throws {
        try SQLiteResultHandler.verifyResultCode(sqlite3_rekey(handle, key, Int32(key.utf8.count)), forHandle: handle)
    }
    #endif
}




