//
//  Database.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 28/12/15.
//

import Foundation

//// TODO: Allow queues working on different databases at the same time

internal class swiftyDbTxn : swiftyDb {
    fileprivate init(swiftyDb: swiftyDb){
        super.init(database: swiftyDb.database)
        self.existingTables = swiftyDb.existingTables
    }
    internal override var transactioning : Bool{
        return true
    }
    //internal override var existingTables: Set<String> = []
    //数据会在txn完成之后丢失。这是正确的
    //为什么不把这个代理到db里面去呢？因为这是一个txn，如果代理进去可能会导致数据错误。
    //如果兴建表了，但这个txn最终失败, db里面的数据就有问题了。所以最好的办法是不要修改原来的数据，
    //等这个txn成功了，其他地方再去判断无非就是在查下表而已。
}


/*
 //https://www.drupal.org/node/669794
 try {
 $txn = db_transaction(); // BEGIN;
 db_insert('node')
 ->values($values);
 ->execute();
 
 try {
 $txn2 = db_transaction(); // SAVEPOINT savepoint_1;
 
 db_insert('node')
 ->values($values2);
 ->execute();
 // Commit second transaction.
 unset($txn2); // RELEASE SAVEPOINT savepoint_1;
 
 }
 catch (Exception $e) {
 $txn2->rollback(); // ROLLBACK TO SAVEPOINT savepoint_1;
 }
 
 // Commit first transaction.
 unset($txn); // COMMIT
 }
 catch (Exception $e) {
 $txn->rollback(); // ROLLBACK;
 }
 */

extension swiftyDb  {
    /** Execute a synchronous transaction on the database in a sequential queue */
    public func transaction(_ block: @escaping ((_ db: SwiftyDb) throws -> Void)) ->Bool {
        do{
            if transactioning{//transaction in transaction
                let startName : String = UUID().uuidString
                do {
                    try database.startSavepoint(startName)
                    try block(self)
                    try database.releaseSavepoint(startName)
                } catch _ {
                    try database.rollbackSavepoint(startName)
                }
            }else{
                try sync {(database) in
                    do {
                        try database.database.beginTransaction()
                        try block(swiftyDbTxn(swiftyDb:self))
                        try database.database.endTransaction()
                    } catch _ {
                        try database.database.rollback()
                    }
                }
            }
        } catch _ {
            return false
        }
        return true
    }
    /** Execute synchronous queries on the database in a sequential queue */
    internal func sync(_ block: @escaping ((_ database: swiftyDb) throws -> Void)) throws {
        /* Run the query in a sequential queue to avoid threading related problems */
        if transactioning{
            try block(self)
        }else{
            var thrownError: Error?
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
}


extension swiftyDb  {
    //!!! TODO need seperate Write and Read
    //need write queue, and read queue
    public func dataFor <S: Storable> (_ obj: S, _ fiter: Filter? = nil, _ checkTableExist:Bool=true) -> Result<[[String: Value?]]> {
        
        var results: [[String: Value?]] = []
        do {
            if checkTableExist{
                guard tableExistsForName(obj.tableName()) else {
                    return Result.success([])
                }
            }
            
            /* Generate statement */
            let query = StatementGenerator.selectStatementForTableName(obj.tableName(),  fiter)
            
            try sync { (database) -> Void in
                let parameters = fiter?.parameters() ?? [:]
                let statement = try! database.database.prepare(query)
                    .execute(SqlValues(parameters))
                
                /* Create a dummy object used to extract property data */
                let object =  type(of:obj).init()
                let objectPropertyData = PropertyData.validPropertyDataForObject(object)
                
                results = statement.map { row in
                    self.parsedDataForRow(row, forPropertyData: objectPropertyData)
                }
                
                //Swift.print("query: \(query)")
                //Swift.print("results: \(results.count)")
                //print("statement: \(statement)")
                
                try statement.finalize()
            }
        } catch let error {
            return .Error(error)
        }
        
        // print(results)
        return .success(results)
    }
    
    public func dataFor (_ tableName: String, _ fiter: Filter? = nil, _ checkTableExist:Bool=true) -> Result<[[String: SQLiteValue?]]> {
        
        var results: [[String: SQLiteValue?]] = []
        do {
            if checkTableExist{
                guard tableExistsForName(tableName) else {
                    return Result.success([])
                }
            }
            
            /* Generate statement */
            let query = StatementGenerator.selectStatementForTableName(tableName,  fiter)
            
            try sync { (database) -> Void in
                let parameters = fiter?.parameters() ?? [:]
                let statement = try! database.database.prepare(query)
                    .execute(SqlValues(parameters))
                
                results = statement.map { row in
                    self.parsedDataForRow2(row)
                }
                
                Swift.print("query: \(query)")
                Swift.print("results: \(results.count)")
                
                try statement.finalize()
            }
        } catch let error {
            return .Error(error)
        }
        
        // print(results)
        return .success(results)
    }
}


extension swiftyDb {
    public func objectsFor<D> (_ obj: D, _ filter: Filter? = nil, _ checkTableExist:Bool=true) -> Result<[D]> where D: Storable  {
        let dataResults = dataFor(obj, filter, checkTableExist)
        
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



extension swiftyDb  {
    //by_zouxu need compare add & update
    internal func addObjectInner <S: Storable> (_ object: S, update: Bool = true) -> Result<Bool> {
        //        guard objects.count > 0 else {
        //            return Result.Success(true)
        //        }
        
        //        try database{ (database) -> Void in
        //        }
        do {
            //            if !(tableExistsForName(object.tableName())) {
            //                createTableByObject(object)
            //            }
            self.checkOrCreateTable(object)
            
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
    
    public func addObject<S: Storable> (_ object: S, _ update: Bool = true) -> Result<Bool> {
        var resut : Result<Bool> = Result.success(true)
        try! sync { (database) -> Void in
            resut = database.addObjectInner(object, update:update)
        }
        return resut
    }
    //    public func addObjects <S: Storable> (_ object: S, _ moreObjects: S...) -> Result<Bool> {
    //        return addObjects([object] + moreObjects)
    //    }
    public func addObjects <S: Storable> (_ objects: [S], _ update: Bool = true) -> Result<Bool> {
        guard objects.count > 0 else {
            return Result.success(true)
        }
        do{
            try self.transaction { (db:SwiftyDb) in
                let db = db as! swiftyDb
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
    
    public func deleteObjectsForType (_ type: Storable, _ filter: Filter? = nil) -> Result<Bool> {
        return self.deleteObjectsForTableName(type.tableName(), filter)
    }
    internal func deleteObjectsForTableName (_ tableName: String, _ filter: Filter? = nil) -> Result<Bool> {
        do {
            guard tableExistsForName(tableName) else {
                return Result.success(true)
            }
            
            let deleteStatement = StatementGenerator.deleteStatementForName(tableName, matchingFilter: filter)
            
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
extension swiftyDb {
    public func query(_ sql: String, _ data: SqlValues? = nil, _ cb:((StatementData)->Void)?=nil){
        do {
            try database.query(sql, data, cb)
        } catch _ {
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


extension swiftyDb {
    func with(_ obj: Storable)->Filter{
        return Filter.init(self, obj)
    }
}










