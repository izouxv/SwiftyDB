//
//  ViewController.swift
//  SwiftyDBExample
//
//  Created by zouxu on 3/28/17.
//  Copyright © 2017 zouxu. All rights reserved.
//

import UIKit
import SwiftyDB

extension NSObject: Storable  {
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func SwiftXDb(databaseName: String)->SwiftyDb{
        let database = SwiftyDb_Init(databaseName: databaseName)
        try! database.open()
        return database
    }
    
    func SwiftXDbReset(databaseName: String)->SwiftyDb{
        delDBfile(databaseName)
        return SwiftXDb(databaseName: databaseName)
    }
    
    func delDBfile(_ databaseName: String){
        let documentsDir : String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = documentsDir + "/" + databaseName + ".sqlite"
        if FileManager.default.fileExists(atPath: path){
            let _ = try! FileManager.default.removeItem(atPath: path)
        }
    }
    

    func timestamp()->Int{//1/1000 second
        let nowDouble = Date().timeIntervalSince1970
        return Int(nowDouble*1000)
    }
    
    @IBOutlet weak var numInput: UITextField!
    @IBOutlet weak var statTextView: UITextView!
    @IBAction func startBtn(_ sender: Any) {
        database = SwiftXDb(databaseName: "test_databa123123se")
        let num = Int(numInput.text!)!
      
        testAdd(num)
        testGet(num)
    }
    
    func LogOut(_ string : String){
        statTextView.text = statTextView.text + string + "\n"
    }
    
    var database : SwiftyDb!
    
    func testAdd(_ maxItem: Int){
        let time1 = timestamp()
        defer {
            let takeTime = timestamp() - time1
            let timeStr = "\(takeTime/1000).\(takeTime%1000)"
            LogOut("add \(maxItem) take \(timeStr) second")
        }
        
        for i in 0..<maxItem{
            let object = TestClassSimple()
            object.primaryKey = NSNumber(value:i)
            object.num = NSNumber(value:i)
            
            let ok = database.transaction({(db:SwiftyDb, rollback:inout Bool) in
                let suc = db.addObject(object, true).isSuccess
            })
        }
    }
    
    func testAddInTxn(_ maxItem: Int){
        let time1 = timestamp()
        defer {
            let takeTime = timestamp() - time1
            let timeStr = "\(takeTime/1000).\(takeTime%1000)"
            LogOut("add in txn \(maxItem) take \(timeStr) second")
        }
        
        let ok = database.transaction({(db:SwiftyDb, rollback:inout Bool) in
        for ii in 0..<maxItem{
            let i = ii+1000000
            let object = TestClassSimple()
            object.primaryKey = NSNumber(value:i)
            object.num = NSNumber(value:i)
            
                let suc = db.addObject(object, true).isSuccess
            
        }
            })
    }
    
    func testGet(_ maxItem: Int){
        let time1 = timestamp()
        defer {
            let takeTime = timestamp() - time1
            let timeStr = "\(takeTime/1000).\(takeTime%1000)"
            LogOut("get \(maxItem) take \(timeStr) second")
        }
        
        for i in 0..<maxItem{
            let object = TestClassSimple()
            object.primaryKey = NSNumber(value:i)
            let filter = Filter.equal("primaryKey", value:Int(object.primaryKey))
            let ret = database.objectsFor(object, filter, true)
        }
    }
}

