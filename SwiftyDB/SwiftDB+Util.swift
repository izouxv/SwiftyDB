//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation


//a declaration cannot be both 'final' and 'dynamic'
//This issue arises because Swift is trying to generate a dynamic accessor for the static property for Obj-C compatibility, since the class inherits from NSObject.
//If your project is in Swift only, rather than using a var accessor you can avoid the issue via the @nonobjc attribute in Swift 2.0
//extension SwiftyDB  {
    //@nonobjc
//    static let defaultDB : SwiftyDB = SwiftyDB.init(databaseName: "SwiftyDB")
//}

extension SwiftyDB  {
    
    
    // MARK: - Private functions
    
    /**
     Creates a new table for the specified type based on the provided column definitions
     
     The parameter is an object, instead of a type, to avoid forcing the user to implement initialization methods such as 'init'
     
     - parameter type:   type of objects data in the table represents
     
     - returns:          Result type indicating the success of the query
     */
    
    internal func createTableForTypeRepresentedByObject <S: Storable> (_ object: S) -> Result<Bool> {
        
        let statement = StatementGenerator.createTableStatementForTypeRepresentedByObject(object)
        
        do {
            try database({ (database) -> Void in
                try database.database.prepare(statement)
                    .executeUpdate()
                    .finalize()
            })
        } catch let error {
            return .Error(error)
        }
        
        existingTables.insert(tableNameForType(S))
        
        return .success(true)
    }
    
    /**
     Serialize the object
     
     - parameter object:    object containing the data to be extracted
     
     - returns:             dictionary containing the data from the object
     */
    
    internal func dataFromObject (_ object: Storable) -> [String: SQLiteValue?] {
        var dictionary: [String: SQLiteValue?] = [:]
        
        for propertyData in PropertyData.validPropertyDataForObject(object) {
            dictionary[propertyData.name!] = propertyData.value as? SQLiteValue
        }
        
        return dictionary
    }
    
    /**
     Check whether a table representing a type exists, or not
     
     - parameter type:  type implementing the Storable protocol
     
     - returns:         boolean indicating if the table exists
     */
    
//    internal func tableExistsForType(_ type: Storable.Type) throws -> Bool {
//        let tableName = tableNameForType(type)
//        return try self.tableExistsForName(tableName)
//    }
    
    
    internal func tableExistsForObj(_ obj: Storable) throws -> Bool {
        let tableName = tableNameForObj(obj)
        return try self.tableExistsForName(tableName)
    }
    
    internal func tableExistsForName(_ tableName: String) throws -> Bool {
        var exists: Bool = existingTables.contains(tableName)
        
        /* Return true if the result is cached */
        guard !exists else {
            return exists
        }
        
        try database({ (database) in
            exists = try database.database.containsTable(tableName)
        })
        
        /* Cache the result */
        if exists {
            existingTables.insert(tableName)
        }
        
        return exists
    }
    /**
     Used to create name of the table representing a type
     
     - parameter type:  type for which to generate a table name
     
     - returns:         table name as a String
     */
    internal func tableNameForType(_ type: Storable.Type) -> String {
        return String(describing: type)
    }
    internal func tableNameForObj(_ obj: Storable) -> String {
        return String(describing: type(of:obj))
    }
    
    /**
     Create a dictionary with values matching datatypes based on some property data
     
     - parameter row:           row, in the form of a wrapped SQLite statement, from which to receive values
     - parameter propertyData:  array containing information about property names and datatypes
     
     - returns:                 dictionary containing data of types matching the properties of the target type
     */
    
    internal func parsedDataForRow(_ row: Statement, forPropertyData propertyData: [PropertyData]) -> [String: Value?] {
        var rowData: [String: Value?] = [:]
        
        for propertyData in propertyData {
            let value = valueForProperty(propertyData, inRow: row)
            rowData[propertyData.name!] = value
        }
        
        return rowData
    }
    
    /**
     Retrieve the value for a property with the correct datatype
     
     - parameter propertyData:  object containing information such as property name and type
     - parameter row:           row, in the form of a wrapped SQLite statement, from which to retrieve the value
     
     - returns:                 optional value for the property
     */
    
    internal func valueForProperty(_ propertyData: PropertyData, inRow row: Statement) -> Value? {
        if row.typeForColumn(propertyData.name!) == .Null {
            return nil
        }
        
        switch propertyData.type {
        case is Date.Type:    return row.dateForColumn(propertyData.name!) as? Value
        case is Data.Type:    return row.dataForColumn(propertyData.name!) as? Value
        case is NSNumber.Type:  return row.numberForColumn(propertyData.name!) as? Value
            
        case is String.Type:    return row.stringForColumn(propertyData.name!) as? Value
        case is NSString.Type:  return row.nsstringForColumn(propertyData.name!) as? Value
        case is Character.Type: return row.characterForColumn(propertyData.name!) as? Value
            
        case is Double.Type:    return row.doubleForColumn(propertyData.name!) as? Value
        case is Float.Type:     return row.floatForColumn(propertyData.name!) as? Value
            
        case is Int.Type:       return row.integerForColumn(propertyData.name!) as? Value
        case is Int8.Type:      return row.integer8ForColumn(propertyData.name!) as? Value
        case is Int16.Type:     return row.integer16ForColumn(propertyData.name!) as? Value
        case is Int32.Type:     return row.integer32ForColumn(propertyData.name!) as? Value
        case is Int64.Type:     return row.integer64ForColumn(propertyData.name!) as? Value
        case is UInt.Type:      return row.unsignedIntegerForColumn(propertyData.name!) as? Value
        case is UInt8.Type:     return row.unsignedInteger8ForColumn(propertyData.name!) as? Value
        case is UInt16.Type:    return row.unsignedInteger16ForColumn(propertyData.name!) as? Value
        case is UInt32.Type:    return row.unsignedInteger32ForColumn(propertyData.name!) as? Value
        case is UInt64.Type:    return row.unsignedInteger64ForColumn(propertyData.name!) as? Value
            
        case is Bool.Type:      return row.boolForColumn(propertyData.name!) as? Value
            
        case is NSArray.Type:
            return NSKeyedUnarchiver.unarchiveObject(with: row.dataForColumn(propertyData.name!)!) as? NSArray
        case is NSDictionary.Type:
            return NSKeyedUnarchiver.unarchiveObject(with: row.dataForColumn(propertyData.name!)!) as? NSDictionary
            
            
        default:                return nil
        }
    }
}
