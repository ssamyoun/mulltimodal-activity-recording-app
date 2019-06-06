//
//  InterfaceController.swift
//  ActivityRecord WatchKit Extension
//
//  Created by Abu Sayeed Mondol on 6/5/19.
//  Copyright © 2019 Sirat Samyoun. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var whatActivityText: WKInterfaceLabel!
    
    @IBAction func labelActivityPressed() {
        presentTextInputController(withSuggestions: [], allowedInputMode:WKTextInputMode.plain, completion: {(results) -> Void in
            if results != nil && results!.count > 0 {
                self.whatActivityText.setText((results?[0] as? String)!)
            }
        })
    }
    
    @IBAction func startActivityPressed() {
        delay(2){
            WKInterfaceDevice.current().play(.success)
            WKInterfaceDevice.current().play(.click)
            self.startLoggingData()
        }
    }
    
    @IBAction func stopActivityPressed() {
        WKInterfaceDevice.current().play(.success)
        WKInterfaceDevice.current().play(.click)
    }
    
    @IBAction func saveBtnPressed() { //save to phone
        
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()){
        //function from stack overflow. Delay in seconds
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
        
    }
    
    func startLoggingData(){
        
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
