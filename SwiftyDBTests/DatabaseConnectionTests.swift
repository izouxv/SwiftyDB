import UIKit
import XCTest
@testable import SwiftyDB

class DatabaseConnectionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let _ = try? FileManager.default.removeItem(atPath: path)
    }
    
    var path: String {
        let documentsDirectory : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        return documentsDirectory+"/testDatabase.sqlite"
    }

    func testDatabaseIsOpened() {
        let database = DatabaseConnection(path: path)

        XCTAssertFalse(database.IsOpen())
        XCTAssertNotNil(try? database.open())
        XCTAssertTrue(database.IsOpen())
    }
    
    func testDatabaseIsClosed() {
        let database = DatabaseConnection(path: path)
        try! database.open()
        
        XCTAssertNotNil(try? database.close())
        XCTAssertFalse(database.IsOpen())
    }
    
    func testStandardUpdateIsExecuted() {
        let database = DatabaseConnection(path: path)
        try! database.open()
        
        XCTAssertNotNil(try? database.prepare("CREATE TABLE TestTable (integer INTEGER, text TEXT, date INTEGER)").executeUpdate().finalize())
        
        try! database.close()
    }
    
    func testBindingsUpdateIsExecuted() {
        let database = DatabaseConnection(path: path)
        try! database.open()
        
        try! database.prepare("CREATE TABLE TestTable (integer INTEGER, text TEXT, date INTEGER)").executeUpdate().finalize()
        XCTAssertNotNil(try? database.prepare("INSERT INTO TestTable VALUES (?, ?, ?)").executeUpdate(SqlValues([1, "text", 2])).finalize())
        
        try! database.close()
    }
    
    func testNamedBindingsUpdateIsExecuted() {
        let database = DatabaseConnection(path: path)
        try! database.open()
        
        try! database.prepare("CREATE TABLE TestTable (integer INTEGER, text TEXT, date INTEGER)").executeUpdate().finalize()
        XCTAssertNotNil(try? database.prepare("INSERT INTO TestTable VALUES (:int, :text, :date)").executeUpdate(SqlValues(["int": 1, "text": "text", "date": 2])).finalize())
        
        try! database.close()
    }
    
    func testContainsTableIsCorrect() {
        let database = DatabaseConnection(path: path)
        try! database.open()
        
        XCTAssertFalse(try! database.containsTable("TestTable"))
        XCTAssertNotNil(try? database.prepare("CREATE TABLE TestTable (integer INTEGER, text TEXT, date INTEGER)").executeUpdate().finalize())
        XCTAssertTrue(try! database.containsTable("TestTable"))
        
        try! database.close()
    }
    
    func testBeginsTransaction() {
        let database = DatabaseConnection(path: path)
        try! database.open()
        
        XCTAssertNotNil(try? database.beginTransaction())
        
        try! database.close()
    }

    func testEndsTransaction() {
        let database = DatabaseConnection(path: path)
        try! database.open()
        
        try! database.beginTransaction()
        XCTAssertNotNil(try? database.endTransaction())
        
        try! database.close()
    }
    
    func testRollsBackTransaction() {
        let database = DatabaseConnection(path: path)
        try! database.open()
        
        try! database.beginTransaction()
        XCTAssertNotNil(try? database.rollback())
        
        try! database.close()
    }
}
