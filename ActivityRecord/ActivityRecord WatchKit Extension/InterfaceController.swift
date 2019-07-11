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
    let scannedLabelTitle = "Timestamp, UUID, RSSI \n"
    var scanTimer : Timer?
    var fileWriteTimer : Timer?
    
//    enum AppStates {
//        static let Neutral = 0
//        static let StartPressed = 1
//        static let StopPressed = 2
//        static let SavePressed = 3
//    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        //labelBtn.setHidden(true)
        //whatActivityText.setHidden(true)
        workoutManager.delegate = self
        activateSessionInWatch()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        //transferFileToPhone()
    }
    
    @objc func onScanTimerTick() -> Void {
        if(currentAppState == 1){
            if centralManager.state == .poweredOn {
                centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
            }
        }
        else{ //safe
            scanTimer?.invalidate()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        if central.state == .poweredOn {
//            print("Bluetooth is On")
//        centralManager.scanForPeripherals(withServices: nil, options: nil)
//        } else {
//            print("Bluetooth is not active")
//        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("peripheral: \(peripheral)")  //print("RSSI   : \(RSSI)")
        let str = String(Date().millisecondsSince1970) + ", " + peripheral.identifier.uuidString + ", " + RSSI.stringValue + "\n"
        if(self.currentReader == 1){
            currentScannedDevices1 = currentScannedDevices1 + str
        } else if(self.currentReader == 2){
            currentScannedDevices2 = currentScannedDevices2 + str
        }
        guard let localName = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString else {
            //print("could not retrieve local name")
            return
        }
        if localName.length > 0 {
            //print("found the device")
            centralManager.stopScan()
            self.peripheral = peripheral
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //print("discovered services")
        for service in peripheral.services! {
            let thisService = service as CBService
            peripheral.discoverCharacteristics(nil, for: thisService)
            //print("discovered characteristics")
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
    //var active = false
    
    var gravityStr = ""
    var attitudeStr = ""
    var userAccelStr = ""
    var rotationRateStr = ""
    
    let activityLabelTitle = "Timestamp, UserAccX, UserAccY, UserAccZ, GravX, GravY, GravZ, RotatX, RotatY, RotatZ \n"
    let tagChoices = ["Left","Right"]
    
    @IBOutlet weak var labelBtn: WKInterfaceButton!
    @IBAction func labelActivityPressed() {
        presentTextInputController(withSuggestions: tagChoices, allowedInputMode:WKTextInputMode.plain, completion: {(results) -> Void in
            if results != nil && results!.count > 0 {
                self.currentHand = (results?[0] as? String)!
                self.whatActivityText.setText(self.currentHand)
            }
        })
    }
    
    var currentReader = 0 //1 or 2
    var currentIMUReadings1 = ""
    var currentIMUReadings2 = ""
    var currentAppState = 0
    var currentScannedDevices1 = ""
    var currentScannedDevices2 = ""
    var currentHand = ""
    var currentActivityFileName = ""
    var currentBeaconFileName = ""
    
    @IBAction func startActivityPressed() { //also performs reset
        resetCurrentValues()
        currentAppState = 1
        //shouldScanningStop = false
        whatActivityText.setText("Started")
        WKInterfaceDevice.current().play(.success)
        WKInterfaceDevice.current().play(.click)
        writeInitialLinesToFilesForNewRecording()
        currentReader = 1
        workoutManager.startWorkout()
        scanTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(onScanTimerTick), userInfo: nil, repeats: true)
        RunLoop.current.add(scanTimer!, forMode: RunLoop.Mode.common)
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        fileWriteTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(onWritetoFileTimeTick), userInfo: nil, repeats: true)
        RunLoop.current.add(fileWriteTimer!, forMode: RunLoop.Mode.common)
        setWatchTimerinDisplay()
    }
    
    @IBAction func stopActivityPressed() {
        if(currentAppState == 1) //necessary? multiple saves allows??
        {
            currentAppState = 2
            onWritetoFileTimeTick()
            whatActivityText.setText("Stopped")
            WKInterfaceDevice.current().play(.success)
            WKInterfaceDevice.current().play(.click)
            workoutManager.stopWorkout()
            centralManager.stopScan()
            fileWriteTimer?.invalidate()
            WKTimer.stop()
            //currentScannedDevices2.maxi
        }
    }

    @IBAction func saveBtnPressed() { //transfer to phone and clear file
        if(currentAppState == 2) //necessary? multiple saves allows??
        {
            currentAppState = 3
//            readWholeFileToDataAndSendToPhone(fileName: currentActivityFileName, key: "IMU")
//            readWholeFileToDataAndSendToPhone(fileName: currentBeaconFileName, key: "BC")
            transferFileToPhone(fileName: currentActivityFileName)
            transferFileToPhone(fileName: currentBeaconFileName)

            //can transfer differently?
            //clear file
            whatActivityText.setText("Saved")
            delay(1){
                self.whatActivityText.setText("Handwashing App")
            }
            resetCurrentValues()
        }
        //transferFileToPhone()
    }
    
    func readWholeFileToDataAndSendToPhone(fileName: String, key: String)
    {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName + ".txt")
            do {
                let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
                print(fileContents)
                self.session?.sendMessage([key: fileContents], replyHandler: nil, errorHandler: { error in
                    print("Error sending message",error)
                })
            }
            catch {}
        }
    }
    
    func transferFileToPhone(fileName: String) //func transferFileToPhone(fileName: String, key: String)
    {
//        do {
//            let appContext = ["key1" : "watch", "key2" : "appcontext", "time" : "\(Date())"]
//            try session?.updateApplicationContext(appContext)
//        } catch {
//            print("\(error)")
//        }
//        let userInfo = ["key1" : "watch", "key2" : "userinfo", "time" : "\(Date())"]
//        session?.transferUserInfo(userInfo)
        //below worked
//        let fileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "ase", ofType: "txt")!)
//        let data = ["key1" : "watch", "key2" : "filetransfer", "time" : "\(Date())"]
//        session?.transferFile(fileURL, metadata: data)
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName + ".txt")
            let data = ["key1" : "watch", "key2" : "filetransfer", "time" : "\(Date())"]
            session?.transferFile(fileURL, metadata: data)
        }
        
    }
    //self.session?.transferFile(fileURL, metadata: nil)
    //let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
    //                self.session?.sendMessageData(data, replyHandler: nil, errorHandler: { error in
    //                    print("Error sending to phone",error)
    //                })
    
    @objc func onWritetoFileTimeTick() -> Void {
        if(self.currentReader == 1){
                self.currentIMUReadings2 = ""
                self.currentScannedDevices2 = ""
                self.currentReader = 2
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.appendStringtoWatchFile(str: self.currentIMUReadings1, filename: self.currentActivityFileName + ".txt")
                    //print("WRITTEN==>" + self.currentIMUReadings1)
                    self.appendStringtoWatchFile(str: self.currentScannedDevices1, filename: self.currentBeaconFileName + ".txt")
                    //print("WRITTEN==>" + self.currentScannedDevices1)
                    self.currentIMUReadings1 = ""
                    self.currentScannedDevices1 = ""
            }
        }
        else if(self.currentReader == 2){
                self.currentIMUReadings1 = ""
                self.currentScannedDevices1 = ""
                self.currentReader = 1
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.appendStringtoWatchFile(str: self.currentIMUReadings2, filename: self.currentActivityFileName + ".txt")
                    //print("WRITTEN==>" + self.currentIMUReadings2)
                    self.appendStringtoWatchFile(str: self.currentScannedDevices2, filename: self.currentBeaconFileName + ".txt")
                    //print("WRITTEN==>" + self.currentScannedDevices2)
                    self.currentIMUReadings2 = ""
                    self.currentScannedDevices2 = ""
            }
        }
        else{ //safe
            fileWriteTimer?.invalidate()
        }
    }
    
    func writeInitialLinesToFilesForNewRecording(){
        currentActivityFileName =  "Sensors_" + currentHand + "_" + String(Date().millisecondsSince1970)//self.currentDateAmPmAsString()
        currentBeaconFileName =  "Beacons_" + String(Date().millisecondsSince1970)//self.currentDateAmPmAsString()
        writeStringtoWatchFile(str: currentActivityFileName + "\n" + self.activityLabelTitle, filename: currentActivityFileName + ".txt")
        writeStringtoWatchFile(str: currentBeaconFileName + "\n" + self.scannedLabelTitle, filename: currentBeaconFileName + ".txt")
    }
    
    func resetCurrentValues(){
         currentReader = 0 //1 or 2
         currentIMUReadings1 = ""
         currentIMUReadings2 = ""
         currentAppState = 0
         currentScannedDevices1 = ""
         currentScannedDevices2 = ""
         currentHand = ""
         currentBeaconFileName = ""
         currentActivityFileName = ""
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()){
        //function from stack overflow. Delay in seconds
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
//    func getCurrentMillis()->Int64{
//        return  Int64(NSDate().timeIntervalSince1970 * 1000)
//    }
    
    func didUpdateMotion(_ manager: WorkoutManager, gravityStr: String, rotationRateStr: String, userAccelStr: String, attitudeStr: String, timeStamp: Int64) {
        DispatchQueue.main.async {
            self.gravityStr = gravityStr
            self.userAccelStr = userAccelStr
            self.rotationRateStr = rotationRateStr
            self.attitudeStr = attitudeStr
            let str = String(timeStamp) + ", " + userAccelStr + ", " + gravityStr + ", " + rotationRateStr + ", " + "\n"
            if(self.currentReader == 1){
                self.currentIMUReadings1 = String(self.currentIMUReadings1) + str
            }else if(self.currentReader == 2){
                self.currentIMUReadings2 = String(self.currentIMUReadings2) + str
            }
        }
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        print("finished infotransfer")
    }
    
    func writeStringtoWatchFile(str: String, filename: String){ //+.txt
        let filename = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            try str.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("ERROR in writeStringtoWatchFile")
        }
    }
    
    func appendStringtoWatchFile(str: String, filename: String){
        let filename = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            let data = str.data(using: String.Encoding.utf8, allowLossyConversion: false)!
            let fileHandle = try FileHandle(forWritingTo: filename)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } catch {
            print("ERROR in writeStringtoWatchFile")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func activateSessionInWatch(){
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    @IBOutlet weak var WKTimer: WKInterfaceTimer!

    func setWatchTimerinDisplay(){
        var com = DateComponents()
        com.year = Calendar.current.component(.year, from: Date())//2019
        com.month = Calendar.current.component(.month, from: Date()) //06
        com.day = Calendar.current.component(.day, from: Date()) //11
        let testDate = NSCalendar.current.date(from: com)!
        WKTimer.setDate(testDate)//(Date(timeIntervalSinceNow: duration))
        WKTimer.start()
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
        //active = true
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        //active = false
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
