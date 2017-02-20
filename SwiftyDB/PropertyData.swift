//
//  PropertyData.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 20/12/15.
//

import Foundation

//https://theswiftdev.com/2017/01/05/18-swift-gist-generic-allvalues-for-enums/
protocol EnumCollection: Hashable {
    static var allValues: [Self] { get }
}
extension EnumCollection {
    static func cases() -> AnySequence<Self> {
        typealias S = Self
        return AnySequence { () -> AnyIterator<S> in
            var raw = 0
            return AnyIterator {
                let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else { return nil }
                raw += 1
                return current
            }
        }
    }
    static var allValues: [Self] {
        return Array(self.cases())
    }
}

//judge table attr is correct
enum SqliteKeyWord : String, EnumCollection{
    case
    ABORT,
    ACTION,
    ADD,
    AFTER,
    ALL,
    ALTER,
    ANALYZE,
    AND,
    AS,
    ASC,
    ATTACH,
    AUTOINCREMENT,
    BEFORE,
    BEGIN,
    BETWEEN,
    BY,
    CASCADE,
    CASE,
    CAST,
    CHECK,
    COLLATE,
    COLUMN,
    COMMIT,
    CONFLICT,
    CONSTRAINT,
    CREATE,
    CROSS,
    CURRENT_DATE,
    CURRENT_TIME,
    CURRENT_TIMESTAMP,
    DATABASE,
    DEFAULT,
    DEFERRABLE,
    DEFERRED,
    DELETE,
    DESC,
    DETACH,
    DISTINCT,
    DROP,
    EACH,
    ELSE,
    END,
    ESCAPE,
    EXCEPT,
    EXCLUSIVE,
    EXISTS,
    EXPLAIN,
    FAIL,
    FOR,
    FOREIGN,
    FROM,
    FULL,
    GLOB,
    GROUP,
    HAVING,
    IF,
    IGNORE,
    IMMEDIATE,
    IN,
    INDEX,
    INDEXED,
    INITIALLY,
    INNER,
    INSERT,
    INSTEAD,
    INTERSECT,
    INTO,
    IS,
    ISNULL,
    JOIN,
    KEY,
    LEFT,
    LIKE,
    LIMIT,
    MATCH,
    NATURAL,
    NO,
    NOT,
    NOTNULL,
    NULL,
    OF,
    OFFSET,
    ON,
    OR,
    ORDER,
    OUTER,
    PLAN,
    PRAGMA,
    PRIMARY,
    QUERY,
    RAISE,
    REFERENCES,
    REGEXP,
    REINDEX,
    RELEASE,
    RENAME,
    REPLACE,
    RESTRICT,
    RIGHT,
    ROLLBACK,
    ROW,
    SAVEPOINT,
    SELECT,
    SET,
    TABLE,
    TEMP,
    TEMPORARY,
    THEN,
    TO,
    TRANSACTION,
    TRIGGER,
    UNION,
    UNIQUE,
    UPDATE,
    USING,
    VACUUM,
    VALUES,
    VIEW,
    VIRTUAL,
    WHEN,
    WHERE
}

internal var keyWordSet : Set<String> = {
    let values = SqliteKeyWord.allValues
    var keys : Set<String> = []
    for item in values{
        keys.insert(item.rawValue)
    }
    return keys
}()





internal struct PropertyData {
    
    internal let isOptional: Bool
    internal var type:       Value.Type?  = nil
    internal var name:       String?
    internal var value:      Value?       = nil
    
    internal var isValid: Bool {
        return type != nil && name != nil
    }
    
    internal init(property: Mirror.Child) {
        self.name = property.label
        
        let mirror = Mirror(reflecting: property.value)
        isOptional = mirror.displayStyle == .optional
        value = unwrap(property.value) as? Value
        
        type = typeForMirror(mirror)
    }
    
    internal func typeForMirror(_ mirror: Mirror) -> Value.Type? {
        if !isOptional {
            if mirror.displayStyle == .collection {
                return NSArray.self
            }
            if mirror.displayStyle == .dictionary {
                return NSDictionary.self
            }
            return mirror.subjectType as? Value.Type
        }
        
        // TODO: Find a better way to unwrap optional types
        // Can easily be done using mirror if the encapsulated value is not nil
        
        switch mirror.subjectType {
        case is Optional<String>.Type:      return String.self
        case is Optional<NSString>.Type:    return NSString.self
        case is Optional<Character>.Type:   return Character.self
            
        case is Optional<Date>.Type:      return Date.self
        case is Optional<NSNumber>.Type:    return NSNumber.self
        case is Optional<Data>.Type:      return Data.self
            
        case is Optional<Bool>.Type:        return Bool.self
            
        case is Optional<Int>.Type:         return Int.self
        case is Optional<Int8>.Type:        return Int8.self
        case is Optional<Int16>.Type:       return Int16.self
        case is Optional<Int32>.Type:       return Int32.self
        case is Optional<Int64>.Type:       return Int64.self
        case is Optional<UInt>.Type:        return UInt.self
        case is Optional<UInt8>.Type:       return UInt8.self
        case is Optional<UInt16>.Type:      return UInt16.self
        case is Optional<UInt32>.Type:      return UInt32.self
        case is Optional<UInt64>.Type:      return UInt64.self
            
        case is Optional<Float>.Type:       return Float.self
        case is Optional<Double>.Type:      return Double.self
            
        case is Optional<NSArray>.Type:     return NSArray.self
        case is Optional<NSDictionary>.Type: return NSDictionary.self
            
        default:                            return nil
        }
    }
    
    /**
     
     Unwraps any value
     
     - parameter value:  The value to unwrap
     
     */
    
    internal func unwrap(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        
        if mirror.displayStyle == .collection {
            return NSKeyedArchiver.archivedData(withRootObject: value as! NSArray)
        }
        if mirror.displayStyle == .dictionary {
            return NSKeyedArchiver.archivedData(withRootObject: value as! NSDictionary)
        }
        
        /* Raw value */
        if mirror.displayStyle != .optional {
            return value
        }
        
        /* The encapsulated optional value if not nil, otherwise nil */
        if let value = mirror.children.first?.value {
            return unwrap(value)
        }else{
            return nil
        }
    }
}

extension PropertyData {
    
    internal static func validPropertyDataForObject (_ object: Storable) -> [PropertyData] {
        return validPropertyDataForMirror(Mirror(reflecting: object))
    }
    
    fileprivate static func validPropertyDataForMirror(_ mirror: Mirror, ignoredProperties: Set<String> = []) -> [PropertyData] {
        var ignoredProperties = ignoredProperties
        if mirror.subjectType is IgnoredProperties.Type {
            ignoredProperties = ignoredProperties.union((mirror.subjectType as! IgnoredProperties.Type).ignoredProperties())
        }
        
        var propertyData: [PropertyData] = []
        
        /* Allow inheritance from storable superclasses using reccursion */
        if let superclassMirror = mirror.superclassMirror , superclassMirror.subjectType is Storable.Type {
            propertyData += validPropertyDataForMirror(superclassMirror, ignoredProperties: ignoredProperties)
        }
        
        /* Map children to property data and filter out ignored or invalid properties */
        propertyData += mirror.children.map { PropertyData(property: $0) }
            .filter { $0.isValid && !ignoredProperties.contains($0.name!) }
        
        return propertyData
    }
}
