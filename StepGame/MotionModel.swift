//
//  MotionModel.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/23/24.
//

import Foundation

import CoreMotion

// Protocol that allows delegate ViewController to receive motion data updates
protocol MotionDelegate {
    func activityUpdated(activity: CMMotionActivity)    // E.g., walking, running, stationary
    func pedometerUpdatedToday(steps: Float)            // Today's real-time step updates
    func pedometerUpdatedYesterday(steps: Float)        // Yesterday's steps
}

// MVC model (app state) and related functions for motion activities (e.g., running) and number of steps
class MotionModel{
    
    // MARK: =====Class Variables=====
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    var delegate: MotionDelegate? = nil
    
    // MARK: =====Motion Methods=====
    // Begin tracking iPhone motion activity updates (e.g., walking, running)
    func startActivityMonitoring() {
        // Is activity is available
        if CMMotionActivityManager.isActivityAvailable() {
            // Update from this queue (should we use the MAIN queue here??.... )
            self.activityManager.startActivityUpdates(to: OperationQueue.main)
            {(activity: CMMotionActivity?) -> Void in
                // Unwrap the activity and send to delegate
                // Using the real time pedometer might influences how often we get activity updates...
                // So these updates can come through less often than we may want
                if let unwrappedActivity = activity,
                   let delegate = self.delegate {
                    // Call delegate function
                    delegate.activityUpdated(activity: unwrappedActivity)
                    
                }
            }
        }
        
    }
    
    // Begin tracking step updates from iPhone pedometer
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
