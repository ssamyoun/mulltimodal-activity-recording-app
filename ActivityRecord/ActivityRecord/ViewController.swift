//
//  ViewController.swift
//  ActivityRecord
//
//  Created by Abu Sayeed Mondol on 6/5/19.
//  Copyright © 2019 Sirat Samyoun. All rights reserved.
//

import UIKit
import WatchConnectivity

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970).rounded()) // * 1000.0
    }
}

class ViewController: UIViewController, WCSessionDelegate {

    var session: WCSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activateSessionInPhone()
        // Do any additional setup after loading the view, typically from a nib.
        //NSLog("skbfaksjfb  junnun samyoun")
        //print("sg siratk jsdbv")
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
            //let contentsArr = contents.components(separatedBy: "\n")
            //let fileName:String = contentsArr[0] + ".csv"
            writeStringtoFile(contents:contents, fileName: "fileIMU_" + String(Date().millisecondsSince1970) + ".txt")
        }
        if message.keys.contains("BC") {
            let contents = message["BC"] as! String
            //let contentsArr = contents.components(separatedBy: "\n")
            //let fileName:String = contentsArr[0] + ".csv"
            writeStringtoFile(contents:contents, fileName: "fileBC_" + String(Date().millisecondsSince1970) + ".txt")
        }
    }
    
    
//    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
//        let str = String(decoding: messageData, as: UTF8.self)
//        print("SESSIONDATA" + str)
//    }
    
//    func session(_ session: WCSession, didReceive file: WCSessionFile) {
//            do {
//                let text2 = try String(contentsOf: file.fileURL, encoding: .utf8)
//                print(text2)
//            }
//            catch {/* error handling here */}
////        let data = NSData(contentsOf: file.fileURL)
////        let fileName = file.fileURL.lastPathComponent
////        writeDatatoFile(contents: data! as Data, fileName: fileName)
//    }
    
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

