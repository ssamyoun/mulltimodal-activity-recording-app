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
import CoreLocation
import CoreBluetooth


class InterfaceController: WKInterfaceController, WCSessionDelegate, CBPeripheralDelegate, CBCentralManagerDelegate, WorkoutManagerDelegate {
    
    private var centralManager : CBCentralManager!
    private var peripheral: CBPeripheral!
    //let serviceIds = [CBUUID(string: "10880416-39A2-AF27-E5A8-880975C4F725")]
    var currentScannedDevices = ""
    let scannedLabelTitle = "Timestamp, UUID, RSSI \n"
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        //labelBtn.setHidden(true)
        //whatActivityText.setHidden(true)
        workoutManager.delegate = self
        activateSessionInWatch()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        centralManager.delegate = self
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is On")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth is not active")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("peripheral: \(peripheral)")
        print("RSSI   : \(RSSI)")
        let str = String(self.getCurrentMillis()) + ", " + peripheral.identifier.uuidString + ", " + RSSI.stringValue + "\n"
        currentScannedDevices = currentScannedDevices + str
        guard let localName = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString else {
            print("could not retrieve local name")
            return
        }
        if localName.length > 0 {
            print("found the device")
            centralManager.stopScan()
            self.peripheral = peripheral
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("discovered services")
        for service in peripheral.services! {
            let thisService = service as CBService
            peripheral.discoverCharacteristics(nil, for: thisService)
            print("discovered characteristics")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic
            self.peripheral.setNotifyValue(true, for: thisCharacteristic)
        }
    }
    
    @IBOutlet weak var whatActivityText: WKInterfaceLabel!
    @IBOutlet weak var timeStampLabel: WKInterfaceLabel!
    var session: WCSession?
    var workoutManager = WorkoutManager()
    var active = false
    
    var gravityStr = ""
    var attitudeStr = ""
    var userAccelStr = ""
    var rotationRateStr = ""
    
    var currentIMUReadings = ""
    let activityLabelTitle = "Timestamp, UserAccX, UserAccY, UserAccZ, GravX, GravY, GravZ, RotatX, RotatY, RotatZ \n"
    let tagChoices = ["Left","Right"]
    var currentHand = ""
    
    @IBOutlet weak var labelBtn: WKInterfaceButton!
    @IBAction func labelActivityPressed() {
        presentTextInputController(withSuggestions: tagChoices, allowedInputMode:WKTextInputMode.plain, completion: {(results) -> Void in
            if results != nil && results!.count > 0 {
                self.currentHand = (results?[0] as? String)!
                self.whatActivityText.setText(self.currentHand)
            }
        })
    }
    
    @IBAction func startActivityPressed() {
        //delay(1){
            currentScannedDevices = ""
            currentIMUReadings = ""
            currentHand = ""
        
            whatActivityText.setText("Started")
            WKInterfaceDevice.current().play(.success)
            WKInterfaceDevice.current().play(.click)
            self.workoutManager.startWorkout()
            self.setWatchTimerinDisplay()
        //}
    }
    
    @IBAction func stopActivityPressed() {
        whatActivityText.setText("Stopped")
        WKInterfaceDevice.current().play(.success)
        WKInterfaceDevice.current().play(.click)
        self.workoutManager.stopWorkout()
        isRunning = false
        myTimer?.invalidate()
        WKTimer.stop()
    }

    @IBAction func saveBtnPressed() { //transfer to phone and clear file
        let activityFileName =  "Sensors_" + currentHand + "_" + self.currentDateAmPmAsString()
        self.currentIMUReadings = activityFileName + "\n" + self.activityLabelTitle + "\n" + self.currentIMUReadings
        self.session?.sendMessage(["IMU":self.currentIMUReadings], replyHandler: nil, errorHandler: { error in
            print("Error sending message",error)
        })
        print("Watch Sensors readings sent to phone")
        self.currentIMUReadings = ""
        self.currentHand = ""
        
        let beaconsFileName =  "Beacons_" + self.currentDateAmPmAsString()
        self.currentScannedDevices = beaconsFileName + "\n" + self.scannedLabelTitle + "\n" + self.currentScannedDevices
        self.session?.sendMessage(["BC":self.currentScannedDevices], replyHandler: nil, errorHandler: { error in
            print("Error sending message",error)
        })
        print("Watch Beacons readings sent to phone")
        self.currentScannedDevices = ""
        whatActivityText.setText("Saved")
        delay(1){
            self.whatActivityText.setText("Handwashing App")
        }
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
            let str = String(timeStamp) + userAccelStr + ", " + gravityStr + ", " + rotationRateStr + ", " + "\n"
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
    
    func currentDateAmPmAsString() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let outputString = dateFormatter.string(from: Date())
        return outputString
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


//presentTextInputController(withSuggestions: [], allowedInputMode:WKTextInputMode.plain, completion: {(results) -> Void in
//if results != nil && results!.count > 0 {
//let activityName = (results?[0] as? String)! //"Walking"
//self.whatActivityText.setText(activityName)
//let activityFileName =  String(activityName) + "_" + self.currentDateAmPmAsString()
//self.currentIMUReadings = activityFileName + "\n" + self.activityLabelTitle + "\n" + self.currentIMUReadings
//self.currentIMUReadings = self.currentFileName + "\n" + self.currentIMUReadings + "d, e, f, \n" ////
//self.writetoFile(contents: self.currentIMUReadings, fileName: self.currentFileName)
//self.session?.sendMessage(["IMU":self.currentIMUReadings], replyHandler: nil, errorHandler: { error in
//    print("Error sending message",error)
//})
//print("Watch readings sent to phone")
////self.currentFileName =  ""
//self.currentIMUReadings = ""
////    }
////})
