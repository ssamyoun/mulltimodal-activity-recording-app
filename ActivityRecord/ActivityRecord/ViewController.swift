//
//  ViewController.swift
//  ActivityRecord
//
//  Created by Abu Sayeed Mondol on 6/5/19.
//  Copyright © 2019 Sirat Samyoun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        writetoFile()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func writetoFile(){
//        let msg: String = "testalgk nalga lnf"
//        let fileName = "test-activity record.csv"
//        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
//        do {
//            try msg.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
//        } catch {
//            print("Failed to create file")
//            print("\(error)")
//        }
        
        let str = "Super long string here"
        let filename = getDocumentsDirectory().appendingPathComponent("test-activity record.csv")
        
        do {
            try str.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
        
        
//        let myTextString: String = "testalgk nalga lnf"
//        let destinationPath = NSTemporaryDirectory() + "my_file.txt"
//        var error:NSError?
//        myTextString.write(to: destinationPath, atomically: true, encoding: String.Encoding.utf8)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}

