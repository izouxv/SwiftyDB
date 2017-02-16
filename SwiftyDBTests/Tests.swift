// https://github.com/Quick/Quick

import Quick
import SwiftyDB

func SwiftXDb(databaseName: String)->SwiftyDb{
    let database = SwiftyDb(databaseName: databaseName)
    try! database.open()
    return database
}

class SwiftyDBSpec: QuickSpec {
    override func spec() {        
        let documentsDir : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = documentsDir+"/test_database.sqlite"
        if FileManager.default.fileExists(atPath: path){ 
            let _ = try! FileManager.default.removeItem(atPath: path)
        }
    }
}
