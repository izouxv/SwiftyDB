//
//  SwiftyDB+Asynchronous.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 13/01/16.
//



/** Support asynchronous queries */
extension SwiftyDB {
    
    /** A global, concurrent queue with default priority */
    internal var queueAsync: DispatchQueue {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
    }
    
    /** Execute synchronous queries on the database in a sequential queue */
    public func databaseAsync(_ block: @escaping ((_ database: SwiftyDB) throws -> Void)) throws {
        var thrownError: Error?
        
        /* Run the query in a sequential queue to avoid threading related problems */
        queueAsync.async { () -> Void in
            
            /* Open the database and execute the block. Pass on any errors thrown */
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


#if false
    extension SwiftyDB {
        
        // MARK: - Asynchronous dynamic initialization
        
        /**
         Asynchronous retrieval of objects of a specified type, matching a set of filters, from the database
         
         - parameter filters:   dictionary containing the filters identifying objects to be retrieved
         - parameter type:      type of the objects to be retrieved
         */
        
        internal func asyncObjectsForType <D> (_ type: D.Type, matchingFilter filter: Filter? = nil, withCompletionHandler completionHandler: @escaping ((Result<[D]>)->Void)) where D: Storable {
            
            queueAsync.async { [unowned self] () -> Void in
                completionHandler(self.objectsForType(type, matchingFilter: filter))
            }
        }
    }
    
    
    
    
    
    
    /** Support asynchronous queries */
    extension SwiftyDB {
        
        // MARK: - Asynchronous database operations
        
        /**
         Asynchronously add object to the database
         
         - parameter object:    object to be added to the database
         - parameter update:    indicates whether the record should be updated if already present
         */
        
        internal func asyncAddObject <S: Storable> (_ object: S, update: Bool = true, withCompletionHandler completionHandler: ((Result<Bool>)->Void)? = nil) {
            asyncAddObjects([object], update: update, withCompletionHandler: completionHandler)
        }
        
        /**
         Asynchronously add objects to the database
         
         - parameter objects:    objects to be added to the database
         - parameter update:     indicates whether the record should be updated if already present
         */
        
        internal func asyncAddObjects <S: Storable> (_ objects: [S], update: Bool = true, withCompletionHandler completionHandler: ((Result<Bool>)->Void)? = nil) {
            queueAsync.async { [weak self] () -> Void in
                guard self != nil else {
                    return
                }
                
                completionHandler?(self!.addObjects(objects))
            }
        }
        
        /**
         Asynchronous retrieval of data for a specified type, matching a filter, from the database
         
         - parameter filters:   dictionary containing the filters identifying objects to be retrieved
         - parameter type:      type of the objects to be retrieved
         */
        
        internal func asyncDataForType <S: Storable> (_ type: S.Type, matchingFilter filter: Filter? = nil, withCompletionHandler completionHandler: @escaping ((Result<[[String: Value?]]>)->Void)) {
            
            queueAsync.async { [weak self] () -> Void in
                guard self != nil else {
                    return
                }
                
                completionHandler(self!.dataForType(type, matchingFilter: filter))
            }
        }
        
        /**
         Asynchronously remove objects of a specified type, matching a filter, from the database
         
         - parameter filters:   dictionary containing the filters identifying objects to be deleted
         - parameter type:      type of the objects to be deleted
         */
        
        internal func asyncDeleteObjectsForType (_ type: Storable.Type, matchingFilter filter: Filter? = nil, withCompletionHandler completionHandler: ((Result<Bool>)->Void)? = nil) {
            queueAsync.async { [weak self] () -> Void in
                guard self != nil else {
                    return
                }
                
                completionHandler?(self!.deleteObjectsForType(type, matchingFilter: filter))
            }
        }
    }
    
#endif





