//
//  Filter.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 17/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

/**
 An instance of the Filter class is used to Filter query results
 All Filters are automatically converted into SQLite statements when querying the database.
 
 To make Filtering easier, and backwards compatibility, it is possible to instantiate a Filter object as a dictionary literal
 
 **Example:**
 
 Return any objects with the name 'Ghost'
 
 ```
 let Filter: Filter = ["name": "Ghost"]
 
 let Filter = Filter.equal("name", value: "Ghost")
 ```
 */

public class Filter: FilteerX,ExpressibleByDictionaryLiteral {
    public typealias Key = String
 
    
    fileprivate var db : swiftyDb!
    
    fileprivate var table : Storable!
    
    fileprivate var components: [FilterComponent] = []
    
    fileprivate var extraComponents: [ExtraRelationship:Any] = [:]
 
    init(_ db : swiftyDb, _ table : Storable) {
        self.db = db
        self.table = table
    }
    
    public required init(dictionaryLiteral elements: (Key, Value)...) {
        elements.forEach { (propertyName, value) in
            components.append(FilterComponent(propertyName: propertyName, relationship: .Equal, value: value))
        }
    }
    public init() {}
}
extension Filter{
    public func delete()->Result<Bool>{
        return self.db.deleteObjectsForTableName(table.tableName(), self)
    }
    public func get()->Result<[[String: Value?]]>{
//        self.db.objectsFor(self.table, nil, true)
//        return self.db.objectsFor(self.table, self, true)
        let ss : Result<[[String: Value?]]>? = nil
        return ss!
    }
}
extension Filter {
    //DISTINCT and GRUOP BY , HAVING , MAX, SUM
    fileprivate enum ExtraRelationship: String {
        case Limit   =   "LIMIT"   //[String]
        case OrderBy =   "ORDER BY" //[int]
        case Offset  =   "OFFSET"  //[int]
        //    case JoinTo  =   "LEFTJOIN"
    }
    open func orderBy(_ propertyNames: [String]) -> FilteerX {
        extraComponents[.OrderBy] = propertyNames
        return self
    }
    open func limit(_ limit: Int) -> FilteerX {
        extraComponents[.Limit] = limit
        return self
    }
    open func offset(_ offset: Int) -> FilteerX {
        extraComponents[.Offset] = offset
        return self
    }
    internal func extraStatement() -> String {
        var str = ""
        var key : ExtraRelationship = .OrderBy
        if let data = extraComponents[key] as? [String]{
            str += " \(key.rawValue) " + data.joined(separator: ",")
        }
        key  = .Limit
        if let data = extraComponents[key] as? Int{
            str += " \(key.rawValue) \(data)"
        }
        key  = .Offset
        if let data = extraComponents[key] as? Int{
            str += " \(key.rawValue) \(data)"
        }
        return str
    }
}

extension Filter {
    
    fileprivate enum Relationship: String {
        case Equal =            "="
        case Less =             "<"
        case Greater =          ">"
        case NotEqual =         "!="
        case In =               "IN"
        case NotIn =            "NOT IN"
        case Like =             "LIKE"
        case NotLike =          "NOT LIKE"
        case LessOrEqual =      "<="
        case GreaterOrEqual =   ">="
    }
    
    /** Represent a part of the total Filters (e.g. 'id = 2') */
    fileprivate struct FilterComponent {
        let propertyName: String
        let relationship: Relationship
        let value: Any?
        
        fileprivate let uniqueifier: UInt32 = arc4random()
        
        var uniquePropertyName: String {
            return "\(propertyName)\(uniqueifier)"
        }
        
        func statement() -> String {
            switch relationship {
            case .Equal, .NotEqual, .Greater, .GreaterOrEqual, .Less, .LessOrEqual, .Like, .NotLike:
                return "\(propertyName) \(relationship.rawValue) :\(uniquePropertyName)"
            case .In, .NotIn:
                let array = value as! [Value?]
                let placeholderString = (0..<array.count).map {":\(uniquePropertyName)\($0)"}
                    .joined(separator: ", ")
                
                return "\(propertyName) \(relationship.rawValue) (\(placeholderString))"
            }
        }
    }
    
    // MARK: - Internal methods
    
    internal func whereStatement() -> String {
        let statement = "WHERE " + self.components.map {$0.statement()}.joined(separator: " AND ")
        return statement
    }
    
    internal func parameters() -> [String: SQLiteValue?] {
        var parameters: [String: SQLiteValue?] = [:]
        
        for FilterComponent in components {
            if let arrayValue = FilterComponent.value as? [Value?] {
                for (index, value) in arrayValue.enumerated() {
                    parameters["\(FilterComponent.uniquePropertyName)\(index)"] = value as? SQLiteValue
                }
            } else {
                parameters[FilterComponent.uniquePropertyName] = FilterComponent.value as? SQLiteValue
            }
        }
        
        return parameters
    }
}

extension Filter {
    // MARK: - Filters
    open func equal(_ propertyName: String, value: Value?) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .Equal, value: value))
        return self
    }
    open func lessThan(_ propertyName: String, value: Value?) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .Less, value: value))
        return self
    }
    open func lessOrEqual(_ propertyName: String, value: Value?) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .LessOrEqual, value: value))
        return self
    }
    open func greaterThan(_ propertyName: String, value: Value?) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .Greater, value: value))
        return self
    }
    open func greaterOrEqual(_ propertyName: String, value: Value?) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .GreaterOrEqual, value: value))
        return self
    }
    open func notEqual(_ propertyName: String, value: Value?) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .NotEqual, value: value))
        return self
    }
    open func contains(_ propertyName: String, array: [Value?]) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .In, value: array))
        return self
    }
    open func notContains(_ propertyName: String, array: [Value?]) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .NotIn, value: array))
        return self
    }
    
    /**
     Evaluated as true if the value of the property matches the pattern.
     
     **%** matches any string
     
     **_** matches a single character
     
     'Dog' LIKE 'D_g'    = true
     
     'Dog' LIKE 'D%'     = true
     
     
     - parameter propertyName:  name of the property to be evaluated
     - parameter array:         array that should contain the property value
     
     - returns:                 `self`, to enable chaining of statements
     */
    open func like(_ propertyName: String, pattern: String) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .Like, value: pattern))
        return self
    }
    
    /**
     Evaluated as true if the value of the property matches the pattern.
     
     **%** matches any string
     
     **_** matches a single character
     
     'Dog' NOT LIKE 'D_g'    = false
     
     'Dog' NOT LIKE 'D%'     = false
     
     
     - parameter propertyName:  name of the property to be evaluated
     - parameter array:         array that should contain the property value
     
     - returns:                 `Filter` intance
     */
    open func notLike(_ propertyName: String, pattern: String) -> FilteerX {
        components.append(FilterComponent(propertyName: propertyName, relationship: .NotLike, value: pattern))
        return self
    }
}


/** Convenience methods */
extension Filter {
    public static func equal(_ propertyName: String, value: Value?) -> FilteerX {
        return Filter().equal(propertyName, value: value)
    }
    public static func lessThan(_ propertyName: String, value: Value?) -> FilteerX {
        return Filter().lessThan(propertyName, value: value)
    }
    public static func lessOrEqual(_ propertyName: String, value: Value?) -> FilteerX {
        return Filter().lessOrEqual(propertyName, value: value)
    }
    public static func greaterThan(_ propertyName: String, value: Value?) -> FilteerX {
        return Filter().greaterThan(propertyName, value: value)
    }
    public static func greaterOrEqual(_ propertyName: String, value: Value?) -> FilteerX {
        return Filter().greaterOrEqual(propertyName, value: value)
    }
    public static func notEqual(_ propertyName: String, value: Value?) -> FilteerX {
        return Filter().notEqual(propertyName, value: value)
    }
    public static func contains(_ propertyName: String, array: [Value?]) -> FilteerX {
        return Filter().contains(propertyName, array: array)
    }
    public static func notContains(_ propertyName: String, array: [Value?]) -> FilteerX {
        return Filter().notContains(propertyName, array: array)
    }
    public static func like(_ propertyName: String, pattern: String) -> FilteerX {
        return Filter().like(propertyName, pattern: pattern)
    }
    public static func notLike(_ propertyName: String, pattern: String) -> FilteerX {
        return Filter().notLike(propertyName, pattern: pattern)
    }
}


