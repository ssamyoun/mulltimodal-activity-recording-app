//
//  InterfaceController.swift
//  ActivityRecord WatchKit Extension
//
//  Created by Abu Sayeed Mondol on 6/5/19.
//  Copyright © 2019 Sirat Samyoun. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate, WorkoutManagerDelegate {

    @IBOutlet weak var whatActivityText: WKInterfaceLabel!
    var session: WCSession?
    var workoutManager = WorkoutManager()
    var active = false
    
    var gravityStr = ""
    var attitudeStr = ""
    var userAccelStr = ""
    var rotationRateStr = ""
    
    var currentFileName = "" //activity_datetime
    var currentActivityName = ""
    var currentIMUReadings = "a, b, c, \n"
    
    @IBAction func labelActivityPressed() {

    }
    
    @IBAction func startActivityPressed() {
        delay(2){
            WKInterfaceDevice.current().play(.success)
            WKInterfaceDevice.current().play(.click)
            self.workoutManager.startWorkout()
        }
    }
    
    @IBAction func stopActivityPressed() {
        WKInterfaceDevice.current().play(.success)
        WKInterfaceDevice.current().play(.click)
        self.workoutManager.stopWorkout()
    }

    @IBAction func saveBtnPressed() { //transfer to phone and clear file
        //presentTextInputController(withSuggestions: [], allowedInputMode:WKTextInputMode.plain, completion: {(results) -> Void in
            //if results != nil && results!.count > 0 {
                self.currentActivityName = "Walking"//(results?[0] as? String)!
                self.whatActivityText.setText(self.currentActivityName)
                self.currentFileName =  String(self.currentActivityName) + "_" + String(self.getCurrentMillis())
                self.currentIMUReadings = self.currentIMUReadings + "d, e, f, \n" ////
                self.writetoFile(contents: self.currentIMUReadings, fileName: self.currentFileName)
                print("Pushed to watch file")
                self.currentFileName =  ""
                self.currentActivityName =  ""
                self.currentIMUReadings = ""
                let currentfileUrl = self.getDocumentsDirectory().appendingPathComponent(self.currentFileName)
                self.session?.transferFile(currentfileUrl, metadata: nil)
                print("Watch file sent to phone")
            //}
        //})
        
        //save locally/
        ///
        //let contentsData = NSData(contentsOf: saveURL )
        //sendtoPhone(data:contentsData!)
//        session?.sendMessage(["FileName": whatActivityText], replyHandler: nil, errorHandler: { error in
//            print("Error sending message",error)
//        })
//        let contentsData = NSData(contentsOf: saveURL )
//        session?.sendMessageData(contentsData as Data, replyHandler: { (data) -> Void in
//         //handle the response from the device
//        }) { (error) -> Void in
//            print("error: \(error.localizedDescription)")
//        }

    }
    
    //func sendtoPhone(data: NSData){
        //session?.sendMessageData(data as Data, replyHandler: { (data) -> Void in
            // handle the response from the device
        //}) { (error) -> Void in
        //    print("error: \(error.localizedDescription)")
        //}
    //}
    
    func delay(_ delay:Double, closure:@escaping ()->()){
        //function from stack overflow. Delay in seconds
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
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
    
    func getCurrentMillis()->Int64{
        return  Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
    func didUpdateMotion(_ manager: WorkoutManager, gravityStr: String, rotationRateStr: String, userAccelStr: String, attitudeStr: String) {
        DispatchQueue.main.async {
            self.gravityStr = gravityStr
            self.userAccelStr = userAccelStr
            self.rotationRateStr = rotationRateStr
            self.attitudeStr = attitudeStr
            let str = userAccelStr + "," + rotationRateStr + "," + gravityStr + "\n"
            self.currentIMUReadings = String(self.currentIMUReadings) + str
        }
    }
    
    func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if error != nil {
            print(error?.description)
        }
        else{
            print("File Sent from Watch")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
    }
    
    func activateSessionInWatch(){
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        workoutManager.delegate = self
        activateSessionInWatch()
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        active = true
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        active = false
    }
}
