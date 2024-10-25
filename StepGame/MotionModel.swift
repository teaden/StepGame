//
//  MotionModel.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/23/24.
//

import Foundation

import CoreMotion

// setup a protocol for the ViewController to be delegate for
protocol MotionDelegate {
    // Define delegate functions
    func activityUpdated(activity: CMMotionActivity)
    func pedometerUpdatedToday(steps: Float)
    func pedometerUpdatedYesterday(steps: Float)
}

class MotionModel{
    
    // MARK: =====Class Variables=====
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    var delegate: MotionDelegate? = nil
    
    // MARK: =====Motion Methods=====
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            // update from this queue (should we use the MAIN queue here??.... )
            self.activityManager.startActivityUpdates(to: OperationQueue.main)
            {(activity: CMMotionActivity?) -> Void in
                // unwrap the activity and send to delegate
                // using the real time pedometer might influences how often we get activity updates...
                // so these updates can come through less often than we may want
                if let unwrappedActivity = activity,
                   let delegate = self.delegate {
                    // Call delegate function
                    delegate.activityUpdated(activity: unwrappedActivity)
                    
                }
            }
        }
        
    }
    
    func startPedometerMonitoring() {
        // Ensure pedometer is available
        if CMPedometer.isStepCountingAvailable() {
            let now = Date()
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!

            // Fetch yesterday's steps
            pedometer.queryPedometerData(from: startOfYesterday, to: startOfToday) { [weak self] (pedData, error) in
                if let steps = pedData?.numberOfSteps.floatValue {
                    self?.delegate?.pedometerUpdatedYesterday(steps: steps)
                }
            }

            // Fetch today's steps
            pedometer.startUpdates(from: startOfToday) { [weak self] (pedData, error) in
                if let steps = pedData?.numberOfSteps.floatValue {
                    self?.delegate?.pedometerUpdatedToday(steps: steps)
                }
            }
        }
    }
}
