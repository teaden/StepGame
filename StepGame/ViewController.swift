//
//  ViewController.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/22/24.
//

import UIKit
import CoreMotion
import DGCharts

class ViewController: UIViewController, UITextFieldDelegate  {

    let motionModel = MotionModel()
    var todaySteps: Int = 0
    var yesterdaySteps: Int = 0
    var stepGoal: Int = 0
    private lazy var circularProgressBarView = CircularProgressBarView()

    // MARK: =====UI Outlets=====

    @IBOutlet weak var playGameButton: UIButton!
    @IBOutlet weak var todayStepLabel: UILabel!
    @IBOutlet weak var goalStepLabel: UILabel!
    @IBOutlet weak var editGoalButton: UIButton!
    @IBOutlet weak var stepGoalTextField: UITextField!
    @IBOutlet weak var saveGoalButton: UIButton!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var activityLabel: UILabel!
    
    // MARK: =====UI Actions=====
    @IBAction func tapEditGoalButton(_ sender: UIButton) {
        editGoalButton.isHidden = true
        stepGoalTextField.isHidden = false
        saveGoalButton.isHidden = false
        self.stepGoalTextField.becomeFirstResponder()
    }

    @IBAction func tapSaveGoalButton(_ sender: UIButton) {

        if let enteredText = stepGoalTextField.text, let newGoal = Int(enteredText) {
            self.stepGoal = newGoal
            UserDefaults.standard.set(newGoal, forKey: "stepGoal")
            goalStepLabel.text = "Goal: \(newGoal)"
            updateCircularProgressBar()
            stepGoalTextField.isHidden = true
            saveGoalButton.isHidden = true
            editGoalButton.isHidden = false
        }
        
        self.stepGoalTextField.text = ""
        self.stepGoalTextField.resignFirstResponder()
    }

    // MARK: =====UI Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()

        self.motionModel.delegate = self
        self.motionModel.startActivityMonitoring()
        self.motionModel.startPedometerMonitoring()
        
        playGameButton.isHidden = true
        stepGoalTextField.isHidden = true
        saveGoalButton.isHidden = true

        var savedGoal = UserDefaults.standard.integer(forKey: "stepGoal")
        if savedGoal == 0 {
            savedGoal = 50
            UserDefaults.standard.set(savedGoal, forKey: "stepGoal")
        }
        
        self.stepGoal = savedGoal
        goalStepLabel.text = "Goal: \(savedGoal)"

        configureCircularProgressBarView()
        configureBarChartView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        circularProgressBarView.frame = CGRect(
            x: view.bounds.midX - 85,
            y: view.bounds.midY - 260,
            width: 170,
            height: 170
        )
    }

    func configureCircularProgressBarView() {
        view.addSubview(circularProgressBarView)
        let progress = min(Float(self.todaySteps) / Float(self.stepGoal), 1.0)
        
        circularProgressBarView.setProgress(CGFloat(progress), animated: false)
    }

    func configureBarChartView() {
        barChartView.chartDescription.enabled = false
        barChartView.legend.enabled = false

        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.xAxis.granularity = 1
        barChartView.xAxis.labelCount = 2

        // Enable left axis and disable right axis
        barChartView.leftAxis.enabled = true
        barChartView.leftAxis.axisMinimum = 0
        barChartView.leftAxis.drawGridLinesEnabled = false

        barChartView.rightAxis.enabled = false
    }

    func updateCircularProgressBar() {
        let progress = min(Float(self.todaySteps) / Float(self.stepGoal), 1.0)
        circularProgressBarView.setProgress(CGFloat(progress), animated: false)
        
        if (progress >= 1.0) {
            playGameButton.isHidden = false
        } else {
            playGameButton.isHidden = true
        }
    }

    func updateBarChart() {
        let todaySteps: Int = self.todaySteps
        let yesterdaySteps: Int = self.yesterdaySteps

        DispatchQueue.main.async {
            let entries = [
                BarChartDataEntry(x: 0, y: Double(yesterdaySteps)),
                BarChartDataEntry(x: 1, y: Double(todaySteps))
            ]

            let dataSet = BarChartDataSet(entries: entries, label: "Steps")
            dataSet.colors = [UIColor.systemBlue]
            dataSet.valueFont = UIFont.systemFont(ofSize: 14)
            dataSet.valueFormatter = IntegerValueFormatter()

            let data = BarChartData(dataSet: dataSet)

            // Calculate dates
            let todayDate = Date()
            let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: todayDate)!

            // Format dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"

            let todayDateString = dateFormatter.string(from: todayDate)
            let yesterdayDateString = dateFormatter.string(from: yesterdayDate)

            // Set labels
            let formatter = BarChartFormatter()
            formatter.labels = [yesterdayDateString, todayDateString]
            self.barChartView.xAxis.valueFormatter = formatter

            // Adjust x-axis settings
            self.barChartView.xAxis.granularity = 1
            self.barChartView.xAxis.labelCount = entries.count

            // Adjust left axis maximum
            let maxSteps = max(Double(todaySteps), Double(yesterdaySteps))
            self.barChartView.leftAxis.axisMaximum = maxSteps * 1.5 // Increase by 50%

            self.barChartView.data = data
        }
    }
}

extension ViewController: MotionDelegate {
    // MARK: =====Motion Delegate Methods=====
    func activityUpdated(activity: CMMotionActivity) {
        
        var activityLabel = "Activity: "
        
        updateActivityLabel(label: &activityLabel, newActivityPresent: activity.walking, emoji: "🚶")
        updateActivityLabel(label: &activityLabel, newActivityPresent: activity.running, emoji: "🏃")
        updateActivityLabel(label: &activityLabel, newActivityPresent: activity.stationary, emoji: "📱")
        updateActivityLabel(label: &activityLabel, newActivityPresent: activity.cycling, emoji: "🚴‍♂️")
        updateActivityLabel(label: &activityLabel, newActivityPresent: activity.automotive, emoji: "🚗")
        updateActivityLabel(label: &activityLabel, newActivityPresent: activity.unknown, emoji: "❓")
        
        if activityLabel == "Activity: " {
            activityLabel += "⏺️"
        }
        
        self.activityLabel.text = activityLabel
    }

    func pedometerUpdatedToday(steps: Float) {
        DispatchQueue.main.async {
            let stepsInt = Int(steps)
            self.todaySteps = stepsInt
            self.todayStepLabel.text = "Today: \(stepsInt)"
            self.updateCircularProgressBar()
            self.updateBarChart()
        }
    }

    func pedometerUpdatedYesterday(steps: Float) {
        DispatchQueue.main.async {
            let stepsInt = Int(steps)
            self.yesterdaySteps = stepsInt
            self.updateBarChart()
        }
    }
    
    private func updateActivityLabel(label: inout String, newActivityPresent: Bool, emoji: String) {
        if (newActivityPresent) {
            if label != "Activity: " {
                label += ", "
            }
            label += emoji
        }
    }
}

