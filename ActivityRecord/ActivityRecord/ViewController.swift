//
//  ViewController.swift
//  ActivityRecord
//
//  Created by Abu Sayeed Mondol on 6/5/19.
//  Copyright © 2019 Sirat Samyoun. All rights reserved.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {

    var session: WCSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activateSessionInPhone()
        //writetoFile()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func writetoFile(contents:String, fileName: String){
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try contents.write(to: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let contents = message["Contents"] as! String
        let fileName = message["FileName"] as! String
        writetoFile(contents: contents, fileName: fileName)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func activateSessionInPhone(){
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

}

