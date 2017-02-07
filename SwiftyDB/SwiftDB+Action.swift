//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation

//// TODO: Allow queues working on different databases at the same time
//private let _queue: dispatch_queue_t = dispatch_queue_create("TinySQLiteQueue", nil)


extension SwiftyDB  {
    
    /** Execute a synchronous transaction on the database in a sequential queue */
    public func transaction(_ block: @escaping ((_ db: SwiftyDB) throws -> Void)) ->Bool {
        do{
            try dbSync{(database) in
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
    
    //写需要放在这个同步队列里面，避免事务冲突
    /** Execute synchronous queries on the database in a sequential queue */
    public func dbSync(_ block: @escaping ((_ database: SwiftyDB) throws -> Void)) throws {
        var thrownError: Error?
        
        /* Run the query in a sequential queue to avoid threading related problems */
        queue.sync { () -> Void in
            
            /* Open the database and execute the block. Pass on any errors thrown */
            do {
                //                try self.database.open()
                //
                //                /* Close the database when leaving this scope */
                //                defer {
                //                    try! self.database.close()
                //                }
                
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









extension SwiftyDB {
    
    // MARK: - Dynamic initialization
    
    /**
     Get objects of a specified type, matching a filter, from the database
     
     - parameter filter:   `Filter` object containing the filters for the query
     - parameter type:      type of the objects to be retrieved
     
     - returns:             Result wrapping the objects, or an error, if unsuccessful
     */
    
    public func objectsForType <D> (_ obj: D, matchingFilter filter: Filter? = nil) -> Result<[D]> where D: Storable  {
        let dataResults = dataForType(obj, matchingFilter: filter)
        
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
    
    fileprivate func objectWithData <D> (_ data: [String: Value?], forType type: D.Type) -> D where D: Storable  {
        let object = type.init()
        
        var validData: [String: AnyObject] = [:]
        
        data.forEach { (name, value) -> () in
            if let numValue = value as? UInt64{
                validData[name] = Int(numValue) as AnyObject?
            }else if let validValue = value as? String {
                validData[name] =  String(validValue) as AnyObject?
                //            }else if let validValue = value as? AnyObject {
                //                validData[name] = validValue
            }else{
                Swift.print("not support name: \(name)")
            }
        }
        object.setValuesForKeys(validData)
        return object
    }
}



extension SwiftyDB  {
    //by_zouxu need compare add & update
    public func addObject <S: Storable> (_ object: S, update: Bool = true) -> Result<Bool> {
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
            
            
            //            try dbSync{ (database) in
            
            //这里不应该直接做事务，因为有可能多个操作一起事务
            //try databaseQueue.transaction { (database) -> Void in
            let statement = try database.prepare(insertStatement)
            
            defer {
                /* If an error occurs, try to finalize the statement */
                let _ = try? statement.finalize()
            }
            
            let data = self.dataFromObject(object)
            try statement.executeUpdate(data)
            //}
        } catch let error {
            return Result.Error(error)
        }
        return Result.success(true)
    }
    
    public func addObjects <S: Storable> (_ object: S, _ moreObjects: S...) -> Result<Bool> {
        return addObjects([object] + moreObjects)
    }
    
    public func addObjects <S: Storable> (_ objects: [S], update: Bool = true) -> Result<Bool> {
        guard objects.count > 0 else {
            return Result.success(true)
        }
        do{
            
        try self.transaction { (db:SwiftyDB) in
            for object in objects {
                let result = db.addObject(object, update: update)
                if !result.isSuccess{
                    
                }
            }
            }
        } catch let error {
            return Result.Error(error)
        }
        return Result.success(true)
    }
    
    //    public func deleteObjects<D>(_ obj: D)->Result<Bool> where D : Storable, D: PrimaryKeys{
    //        let keys = obj.primaryKeys()
    //        let key = keys[0]
    //        let value = obj.
    //        let filter = Filter.equal(key, value: msgId)
    //        self.deleteObjectsForType(obj.Type)
    //        //return .success(true)
    //    }
    
    public func deleteObjectsForType (_ type: Storable, matchingFilter filter: Filter? = nil) -> Result<Bool> {
        do {
            guard try tableExistsForObj(type) else {
                return Result.success(true)
            }
            
            let deleteStatement = StatementGenerator.deleteStatementForType(type, matchingFilter: filter)
            
            try dbSync { (database) -> Void in
                try database.database.prepare(deleteStatement)
                    .executeUpdate(filter?.parameters() ?? [:])
                    .finalize()
            }
        } catch let error {
            return .Error(error)
        }
        
        return .success(true)
    }
    
    
    
    public func dataForType <S: Storable> (_ obj: S, matchingFilter filter: Filter? = nil) -> Result<[[String: Value?]]> {
        
        var results: [[String: Value?]] = []
        do {
            guard try tableExistsForObj(obj) else {
                return Result.success([])
            }
            
            /* Generate statement */
            let query = StatementGenerator.selectStatementForType(obj, matchingFilter: filter)
            
            try dbSync { (database) -> Void in
                let parameters = filter?.parameters() ?? [:]
                let statement = try! database.database.prepare(query)
                    .execute(parameters)
                
                
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














