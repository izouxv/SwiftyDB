//
//  SwiftyDB+Asynchronous.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 13/01/16.
//



/** Support asynchronous queries */
extension swiftyDb {
    /** A global, concurrent queue with default priority */
    internal var queueAsync: DispatchQueue {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
    }
    
    /** Execute synchronous queries on the database in a sequential queue */
    public func databaseAsync(_ block: @escaping ((_ database: swiftyDb) throws -> Void)) throws {
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





