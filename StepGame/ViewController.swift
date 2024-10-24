//
//  ViewController.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/22/24.
//

import UIKit
import CoreMotion

class ViewController: UIViewController  {
    
    let motionModel = MotionModel()

    // MARK: =====UI Outlets=====
    @IBOutlet weak var yesterdayStepLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var activityLabel: UILabel!

    
    // MARK: =====UI Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.motionModel.delegate = self
        
        self.motionModel.startActivityMonitoring()
        self.motionModel.startPedometerMonitoring()
    }


    


}

extension ViewController: MotionDelegate{
    // MARK: =====Motion Delegate Methods=====
    
    func pedometerUpdated(pedData:CMPedometerData){

        // display the output directly on the phone
        DispatchQueue.main.async {
            // this updates the progress bar with number of steps, assuming 100 is the maximum for the steps
            
            self.progressBar.progress = pedData.numberOfSteps.floatValue / 100
        }
    }
    
    func activityUpdated(activity: CMMotionActivity) {
        self.activityLabel.text = "🚶: \(activity.walking), 🏃: \(activity.running)"
    }
    
    func pedometerUpdatedToday(steps: Float) {
        DispatchQueue.main.async {
            self.progressBar.progress = steps / 100
        }
    }
    
    func pedometerUpdatedYesterday(steps: Float) {
        DispatchQueue.main.async {
            self.yesterdayStepLabel.text = "Yesterday's Steps: \(steps)"
        }
    }
}
