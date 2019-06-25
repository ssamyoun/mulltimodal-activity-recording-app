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
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func writeStringtoFile(contents:String, fileName: String){
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try contents.write(to: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
    
    func writeDatatoFile(contents:Data, fileName: String){
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try contents.write(to: fileURL, options: .atomic)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if message.keys.contains("IMU") {
            let contents = message["IMU"] as! String
            let contentsArr = contents.components(separatedBy: "\n")
            let fileName:String = contentsArr[0] + ".csv"
            writeStringtoFile(contents:contents, fileName: fileName)
        }
        if message.keys.contains("BC") {
            let contents = message["BC"] as! String
            let contentsArr = contents.components(separatedBy: "\n")
            let fileName:String = contentsArr[0] + ".csv"
            writeStringtoFile(contents:contents, fileName: fileName)
        }
    }
    
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        let data = NSData(contentsOf: file.fileURL)
        let fileName = file.fileURL.lastPathComponent
        writeDatatoFile(contents: data as! Data, fileName: fileName)
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

