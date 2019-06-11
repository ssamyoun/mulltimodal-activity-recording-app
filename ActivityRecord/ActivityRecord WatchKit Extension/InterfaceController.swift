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
    @IBOutlet weak var timeStampLabel: WKInterfaceLabel!
    var session: WCSession?
    var workoutManager = WorkoutManager()
    var active = false
    
    var gravityStr = ""
    var attitudeStr = ""
    var userAccelStr = ""
    var rotationRateStr = ""
    
    var currentFileName = "" //activity_datetime
    var currentActivityName = ""
    var currentIMUReadings = ""
    let labelTitle = "userAccX, userAccY, userAccZ, gravX, gravY, gravZ, rotatX, rotatY, rotatZ, timestamp \n"
    
    
    @IBOutlet weak var labelBtn: WKInterfaceButton!
    @IBAction func labelActivityPressed() {

    }
    
    @IBAction func startActivityPressed() {
//        delay(2){
//            WKInterfaceDevice.current().play(.success)
//            WKInterfaceDevice.current().play(.click)
//            self.workoutManager.startWorkout()
//        }
        setWatchTimerinDisplay()
    }
    
    @IBAction func stopActivityPressed() {
//        WKInterfaceDevice.current().play(.success)
//        WKInterfaceDevice.current().play(.click)
//        self.workoutManager.stopWorkout()
        isRunning = false
        myTimer?.invalidate()
        WKTimer.stop()
    }

    @IBAction func saveBtnPressed() { //transfer to phone and clear file
        presentTextInputController(withSuggestions: [], allowedInputMode:WKTextInputMode.plain, completion: {(results) -> Void in
            if results != nil && results!.count > 0 {
                self.currentActivityName = (results?[0] as? String)! //"Walking"
                self.whatActivityText.setText(self.currentActivityName)
                self.currentFileName =  String(self.currentActivityName) + "_" + String(self.getCurrentMillis())
                self.currentIMUReadings = self.currentFileName + "\n" + self.labelTitle + "\n" + self.currentIMUReadings
                //self.currentIMUReadings = self.currentFileName + "\n" + self.currentIMUReadings + "d, e, f, \n" ////
                //self.writetoFile(contents: self.currentIMUReadings, fileName: self.currentFileName)
                //print("Pushed to watch file") //remove watch file saves later on
                self.session?.sendMessage(["IMU":self.currentIMUReadings], replyHandler: nil, errorHandler: { error in
                    print("Error sending message",error)
                })
                print("Watch readings sent to phone")
                self.currentFileName =  ""
                self.currentActivityName =  ""
                self.currentIMUReadings = ""
            }
        })
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()){
        //function from stack overflow. Delay in seconds
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    func getCurrentMillis()->Int64{
        return  Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
    func didUpdateMotion(_ manager: WorkoutManager, gravityStr: String, rotationRateStr: String, userAccelStr: String, attitudeStr: String, timeStamp: Int64) {
        DispatchQueue.main.async {
            self.gravityStr = gravityStr
            self.userAccelStr = userAccelStr
            self.rotationRateStr = rotationRateStr
            self.attitudeStr = attitudeStr
            let str = userAccelStr + ", " + gravityStr + ", " + rotationRateStr + ", " + String(timeStamp) + "\n"
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
    
    
    @IBOutlet weak var WKTimer: WKInterfaceTimer!
    var myTimer : Timer?  //internal timer to keep track
    var isRunning = false //flag to determine if it is paused or not
    var elapsedTime : TimeInterval = 0.0 //time that has passed between pause/resume
    var duration : TimeInterval = 0.1 //arbitrary number. 1 seconds
    var startTime = NSDate()
    var testDate = Date()
    
    
    func setWatchTimerinDisplay(){
        myTimer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(onTimerTick), userInfo: nil, repeats: false)
        RunLoop.current.add(myTimer!, forMode: RunLoop.Mode.common)
        isRunning = true
        var com = DateComponents()
        com.year = Calendar.current.component(.year, from: Date())//2019
        com.month = Calendar.current.component(.month, from: Date()) //06
        com.day = Calendar.current.component(.day, from: Date()) //11
        testDate = NSCalendar.current.date(from: com)!
        WKTimer.setDate(testDate)//(Date(timeIntervalSinceNow: duration))
        WKTimer.start()
    }
    
    @objc func timerDone(){
        //timer done counting down
        if(isRunning){
            WKTimer.setDate(testDate)
        }else{
            myTimer?.invalidate()
        }
    }
    
    @objc func onTimerTick() -> Void {
        if(isRunning){
            WKTimer.setDate(testDate)
        }else{
            myTimer?.invalidate()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        labelBtn.setHidden(true)
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
