/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the CoreMotion interactions and
 provides a delegate to indicate changes in data.
 */

import Foundation
import CoreMotion
import WatchKit
import os.log
/**
 `MotionManagerDelegate` exists to inform delegates of motion changes.
 These contexts can be used to enable application specific behavior.
 */
protocol MotionManagerDelegate: class {
    func didUpdateMotion(_ manager: MotionManager, gravityStr: String, rotationRateStr: String, userAccelStr: String, attitudeStr: String, timeStamp: Int64)
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded()) // * 1000.0
    }
}

class MotionManager {
    // MARK: Properties
    
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    
    // MARK: Application Specific Constants
    
    // The app is using 50hz data and the buffer is going to hold 1s worth of data.
    let sampleInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)
    
    weak var delegate: MotionManagerDelegate?
    
    var gravityStr = ""
    var rotationRateStr = ""
    var userAccelStr = ""
    var attitudeStr = ""
    var timeStamp: Int64?
    //var offset: Int64?
    
    var recentDetection = false
    
    // MARK: Initialization
    
    init() {
        // Serial queue for sample handling and calculations.
        queue.maxConcurrentOperationCount = 1
        queue.name = "MotionManagerQueue"
        //offset = getOffset()
    }
    
//    func getOffset()-> Int64{
//        NSProcessInfo.processInfo().systemUptime
//        NSTimeIntervalSince19
//        NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
//        NSTimeInterval nowTimeIntervalSince1970 = [[NSDate date] timeIntervalSince1970];
//        self.offset = nowTimeIntervalSince1970 - uptime
//    }
    
    // MARK: Motion Manager
    
    func startUpdates() {
        if !motionManager.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }
        
        os_log("Start Updates");
        
        motionManager.deviceMotionUpdateInterval = sampleInterval
        motionManager.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            
            if deviceMotion != nil {
                self.processDeviceMotion(deviceMotion!)
            }
        }
    }
    
    func stopUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    // MARK: Motion Processing
    
    func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
//        gravityStr = String(format: "X: %.5f Y: %.5f Z: %.5f" ,
//                            deviceMotion.gravity.x,
//                            deviceMotion.gravity.y,
//                            deviceMotion.gravity.z)
//        userAccelStr = String(format: "X: %.5f Y: %.5f Z: %.5f" ,
//                              deviceMotion.userAcceleration.x,
//                              deviceMotion.userAcceleration.y,
//                              deviceMotion.userAcceleration.z)
//        rotationRateStr = String(format: "X: %.5f Y: %.5f Z: %.5f" ,
//                                 deviceMotion.rotationRate.x,
//                                 deviceMotion.rotationRate.y,
//                                 deviceMotion.rotationRate.z)
//        attitudeStr = String(format: "r: %.5f p: %.5f y: %.5f" ,
//                             deviceMotion.attitude.roll,
//                             deviceMotion.attitude.pitch,
//                             deviceMotion.attitude.yaw)
        //deviceMotion.timestamp
        gravityStr = String(format: "%.5f, %.5f, %.5f" ,
                            deviceMotion.gravity.x,
                            deviceMotion.gravity.y,
                            deviceMotion.gravity.z)
        userAccelStr = String(format: "%.5f, %.5f, %.5f" ,
                              deviceMotion.userAcceleration.x,
                              deviceMotion.userAcceleration.y,
                              deviceMotion.userAcceleration.z)
        rotationRateStr = String(format: "%.5f, %.5f, %.5f" ,
                                 deviceMotion.rotationRate.x,
                                 deviceMotion.rotationRate.y,
                                 deviceMotion.rotationRate.z)
        attitudeStr = String(format: "%.5f, %.5f, %.5f" ,
                             deviceMotion.attitude.roll,
                             deviceMotion.attitude.pitch,
                             deviceMotion.attitude.yaw)
        
        //timeStamp = Int64(deviceMotion.timestamp)
        timeStamp = Date().millisecondsSince1970
        
//_ = Date().millisecondsSince1970
//        os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",
//               String(timestamp),
//               String(deviceMotion.gravity.x),
//               String(deviceMotion.gravity.y),
//               String(deviceMotion.gravity.z),
//               String(deviceMotion.userAcceleration.x),
//               String(deviceMotion.userAcceleration.y),
//               String(deviceMotion.userAcceleration.z),
//               String(deviceMotion.rotationRate.x),
//               String(deviceMotion.rotationRate.y),
//               String(deviceMotion.rotationRate.z),
//               String(deviceMotion.attitude.roll),
//               String(deviceMotion.attitude.pitch),
//               String(deviceMotion.attitude.yaw))
        
        updateMetricsDelegate();
    }
    
    // MARK: Data and Delegate Management
    
    func updateMetricsDelegate() {
        delegate?.didUpdateMotion(self,gravityStr:gravityStr, rotationRateStr: rotationRateStr, userAccelStr: userAccelStr, attitudeStr: attitudeStr, timeStamp: timeStamp!)
    }
}
