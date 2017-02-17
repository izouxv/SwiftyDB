//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation

//// TODO: Allow queues working on different databases at the same time
//private let _queue: dispatch_queue_t = dispatch_queue_create("TinySQLiteQueue", nil)


extension SwiftyDb  {
    
    /** Execute a synchronous transaction on the database in a sequential queue */
    public func transaction(_ block: @escaping ((_ db: SwiftyDb) throws -> Void)) ->Bool {
        do{
            try sync{(database) in
                do {
                    try database.database.beginTransaction()
                    try block(self)
                    try database.database.endTransaction()
                } catch let error {
                    try database.database.rollback()
                }
            }
        } catch let error {
            return false
        }
        return true
    }
    /** Execute synchronous queries on the database in a sequential queue */
    internal func sync(_ block: @escaping ((_ database: SwiftyDb) throws -> Void)) throws {
        var thrownError: Error?
        /* Run the query in a sequential queue to avoid threading related problems */
        
        queue.sync { () -> Void in
            do {
                try block(self)
            } catch let error {
                thrownError = error
            }
        }
        
        /* If an error was thrown during execution, rethrow it */
        // TODO: Improve the process of passing along the error
        guard thrownError == nil else {
            throw thrownError!
        }
    }
}


extension SwiftyDb  {
    //!!! TODO need seperate Write and Read
    //need write queue, and read queue
    public func dataFor <S: Storable> (_ obj: S, matchingFilter filter: Filter? = nil, _ checkTableExist:Bool=true) -> Result<[[String: Value?]]> {
        
        var results: [[String: Value?]] = []
        do {
            if checkTableExist{
                guard try tableExistsForObj(obj) else {
                    return Result.success([])
                }
            }
            
            /* Generate statement */
            let query = StatementGenerator.selectStatementForType(obj, matchingFilter: filter)
            
            try sync { (database) -> Void in
                let parameters = filter?.parameters() ?? [:]
                let statement = try! database.database.prepare(query)
                    .execute(SqlValues(parameters))
                
                /* Create a dummy object used to extract property data */
                let object =  type(of:obj).init()
                let objectPropertyData = PropertyData.validPropertyDataForObject(object)
                
                results = statement.map { row in
                    self.parsedDataForRow(row, forPropertyData: objectPropertyData)
                }
                
                Swift.print("query: \(query)")
                Swift.print("results: \(results.count)")
                //print("statement: \(statement)")
                
                try statement.finalize()
            }
        } catch let error {
            return .Error(error)
        }
        
        // print(results)
        return .success(results)
    }
    
}


extension SwiftyDb {
    public func objectsFor <D> (_ obj: D, matchingFilter filter: Filter? = nil, _ checkTableExist:Bool=true) -> Result<[D]> where D: Storable  {
        let dataResults = dataFor(obj, matchingFilter: filter, checkTableExist)
        
        if !dataResults.isSuccess {
            return .Error(dataResults.error!)
        }
        
        let objects: [D] = dataResults.value!.map {
            objectWithData($0, forType: D.self)
        }
        
        return .success(objects)
    }
    
    
    /**
     Creates a new dynamic object of a specified type and populates it with data from the provided dictionary
     
     - parameter data:   dictionary containing data
     - parameter type:   type of object the data represents
     
     - returns:          object of the provided type populated with the provided data
     */
    
    //fileprivate
    internal func objectWithData <D> (_ data: [String: Value?], forType type: D.Type) -> D where D: Storable  {
        let object = type.init()
        
        #if false
            var validData: [String: Any] = [:]
            
            data.forEach { (name, value) -> () in
                if let numValue = value as? UInt64{
                    validData[name] = Int(numValue)
                }else if let validValue = value as? String {
                    validData[name] =  String(validValue)
                    //            }else if let validValue = value as? AnyObject {
                    //                validData[name] = validValue
                }else{
                    Swift.print("not support name: \(name) \(type(of:value))")
                }
            }
            object.setValuesForKeys(validData)
        #endif
        object.setValuesForKeys(data)
        return object
    }
}



extension SwiftyDb  {
    //by_zouxu need compare add & update
    internal func addObjectInner <S: Storable> (_ object: S, update: Bool = true) -> Result<Bool> {
        //        guard objects.count > 0 else {
        //            return Result.Success(true)
        //        }
        
        //        try database{ (database) -> Void in
        //        }
        do {
            if !(try tableExistsForObj(object)) {
                createTableForTypeRepresentedByObject(object)
            }
            
            let insertStatement = StatementGenerator.insertStatementForType(object, update: update)
            
            //try databaseQueue.transaction { (database) -> Void in
            let statement = try database.prepare(insertStatement)
            
            defer {
                /* If an error occurs, try to finalize the statement */
                let _ = try? statement.finalize()
            }
            
            let data = self.dataFromObject(object)
            try statement.executeUpdate(SqlValues(data))
            
        } catch let error {
            return Result.Error(error)
        }
        return Result.success(true)
    }
    
    public func addObject<S: Storable> (_ object: S, update: Bool = true) -> Result<Bool> {
        var resut : Result<Bool> = Result.success(true)
        try! sync { (database) -> Void in
            resut = self.addObjectInner(object, update:update)
        }
        return resut
    }
    //    public func addObjects <S: Storable> (_ object: S, _ moreObjects: S...) -> Result<Bool> {
    //        return addObjects([object] + moreObjects)
    //    }
    public func addObjects <S: Storable> (_ objects: [S], update: Bool = true) -> Result<Bool> {
        guard objects.count > 0 else {
            return Result.success(true)
        }
        do{
            try self.transaction { (db:SwiftyDb) in
                for object in objects {
                    let result = db.addObjectInner(object, update: update)
                    if !result.isSuccess{
                    }
                }
            }
        } catch let error {
            return Result.Error(error)
        }
        return Result.success(true)
    }
    
    public func deleteObjectsForType (_ type: Storable, matchingFilter filter: Filter? = nil) -> Result<Bool> {
        do {
            guard try tableExistsForObj(type) else {
                return Result.success(true)
            }
            
            let deleteStatement = StatementGenerator.deleteStatementForType(type, matchingFilter: filter)
            
            try sync { (database) -> Void in
                try database.database.prepare(deleteStatement)
                    .executeUpdate(SqlValues(filter?.parameters() ?? [:]))
                    .finalize()
            }
        } catch let error {
            return .Error(error)
        }
        return .success(true)
    }
}
extension SwiftyDb {
    public func query(_ sql: String, _ data: SqlValues? = nil, _ cb:((StatementData)->Void)?=nil){
        do {
            try database.query(sql, data, cb)
        } catch let error {
        }
    }
    public func update(_ statement: String, _ data: SqlValues? = nil)-> Result<Bool>{
        do{
            try database.update(statement, data)
        } catch let error {
            return Result.Error(error)
        }
        return Result.success(true)
    }
}













