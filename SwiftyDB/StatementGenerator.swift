//
//  QueryGenerator.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 27/12/15.
//

import Foundation

internal class StatementGenerator {
    
    //CREATE INDEX salary_index ON COMPANY (salary);
    internal class func createTableIndex (_ object: Storable, _ name:String)throws -> String {
        guard !keyWordSet.contains(name.uppercased()) else {
            Swift.print("!!! [\(object.tableName())] has sqlKeyWork: [\(name)], you need rename")
            throw SQLError.error
        }
        return "CREATE INDEX \(name)_index ON \(object.tableName()) \(name)"
    }
    
    internal class func createTableStatementForTypeRepresentedByObject (_ object: Storable)throws -> String {
        let tableName =  object.tableName() //  tableNameForObj(object)
        
        var statement = "CREATE TABLE " + tableName + " ("
        
        let items = PropertyData.validPropertyDataForObject(object)
        for i in 0..<items.count{
            let propertyData = items[i]
            guard !keyWordSet.contains(propertyData.name!.uppercased()) else {
                Swift.print("!!! [\(object.tableName())] has sqlKeyWork: [\(propertyData.name!)], you need rename")
                throw SQLError.error
            }
            statement += "\(propertyData.name!) \(SQLiteDatatype(type: propertyData.type!)!.rawValue)"
            statement += propertyData.isOptional ? "" : " NOT NULL"
            if i<items.count-1{
                statement += ", "
            }
        }
        
        let objT = type(of:object)
        if objT is PrimaryKeys.Type {
            let primaryKeysType = objT as! PrimaryKeys.Type
            statement += ", PRIMARY KEY (\(primaryKeysType.primaryKeys().joined(separator: ", ")))"
        }
        
        statement += ")"
        
        return statement
    }
    
    internal class func insertStatementForType(_ obj: Storable, update: Bool) -> String {
        var statement = "INSERT OR " + (update ? "REPLACE" : "ABORT") + " INTO " + obj.tableName() // tableNameForObj(obj)
        
        let propertyData = PropertyData.validPropertyDataForObject(type(of:obj).init())
        
        let columns = propertyData.map {$0.name!}
        let namedParameters = columns.map {":" + $0}
        
        /* Columns to be inserted */
        statement += " (" + columns.joined(separator: ", ") + ") "
        
        /* Values to be inserted */
        statement += "VALUES (" + namedParameters.joined(separator: ", ") + ")"
        
        return statement
    }
    
    internal class func selectStatementForTableName(_ tableName: String,_ filtex: Filter?) -> String {
        
        var statement = "SELECT ALL * FROM \(tableName)"
        
        guard filtex != nil else {
            return statement
        }
        
        statement += " " + filtex!.whereStatement()
        
        statement += " " + filtex!.extraStatement()
        
        return statement
    }
    
    internal class func deleteStatementForName(_ tableName: String, matchingFilter filtex: Filter?) -> String {
        var statement = "DELETE FROM \(tableName)"
        
        guard filtex != nil else {
            return statement
        }
        
        statement += " \(filtex!.whereStatement())"
        
        //        statement += filtex!.extraStatement()
        
        return statement
    }
    
    internal class func updateStatementForName(_ tableName: String,_ data: [String:Any], _  filtex: Filter?) -> String {
//        
//        let kvStr = data
//            .map{ key, value in "\(key) = \(PropertyData.unwrap(value) as? Value)"}
//            .joined(separator: ", ")
        
        let kvStr = data
            .map{key, value in "\(key) = :\(key)"}
            .joined(separator: ", ")
        
        var statement = "UPDATE \(tableName) SET \(kvStr)"
        
        guard filtex != nil else {
            return statement
        }
        
        statement += " \(filtex!.whereStatement())"
        
        Swift.print("statment: \(statement)")
        
        return statement
    }
}

//extension StatementGenerator {
//    /** Name of the table representing a class */
//    internal  class func tableNameForObj(_ obj: Storable) -> String {
//        return obj.tableName()
////        return type(of:obj).tableName()
////        if let tableName = type(of:obj).tableName(){
////            return tableName
////        }
////        return String(describing: type(of:obj))
//    }
//}


