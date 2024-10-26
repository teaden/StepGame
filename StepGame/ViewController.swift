//
//  ViewController.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/22/24.
//

import UIKit
import CoreMotion
import DGCharts

// Displays activity (e.g., running); number of steps (today, yesterday, goal); indicates when to play game
class ViewController: UIViewController, UITextFieldDelegate  {

    let motionModel = MotionModel()     // MVC model that tracks motion activity and step updates
    
    var todaySteps: Int = 0             // Real-time updated number of steps taken today
    var yesterdaySteps: Int = 0         // Steps taken yesterday
    var stepGoal: Int = 0               // User settable step goal
    
    var availableArrows: Int = 0        // Game currency acquired based on number of times step goal reached
    
    // Amount of currency used during last gameplay session
    // Used in scenarios where user does not use all available currency (i.e., arrows) in one game
    var firedArrowsLastGame: Int = 0
    
    // Shows step goal progress (i.e., 0% - 100%) in circular UI format rather than in standard progress bar
    private lazy var circularProgressBarView = CircularProgressBarView()

    // MARK: =====UI Outlets=====
    @IBOutlet weak var playGameButton: UIButton!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var todayStepLabel: UILabel!
    @IBOutlet weak var goalStepLabel: UILabel!
    @IBOutlet weak var editGoalButton: UIButton!
    @IBOutlet weak var stepGoalTextField: UITextField!
    @IBOutlet weak var saveGoalButton: UIButton!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var activityLabel: UILabel!

    // MARK: =====UI Actions=====
    // Handler for when user decides to enter new step goal on numpad
    @IBAction func tapEditGoalButton(_ sender: UIButton) {
        editGoalButton.isHidden = true
        stepGoalTextField.isHidden = false
        saveGoalButton.isHidden = false
        self.stepGoalTextField.becomeFirstResponder()
    }
    
    // Hnadler that saves newly entered step goal via numpad
    @IBAction func tapSaveGoalButton(_ sender: UIButton) {
        if let enteredText = stepGoalTextField.text, let newGoal = Int(enteredText) {
            self.stepGoal = newGoal
            UserDefaults.standard.set(newGoal, forKey: "stepGoal")
            goalStepLabel.text = "Goal: \(newGoal)"
            
            // Notify user that resetting step goal forfeits any arrows unused from last game
            if firedArrowsLastGame > 0 {
                firedArrowsLastGame = 0
                let alert = UIAlertController(title: "Notice", message: "Changing the step goal forfeits unfired arrows from last game.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
            
            updateCircularProgressBar()         // See if today's steps exceed newly entered step goal
            stepGoalTextField.isHidden = true
            saveGoalButton.isHidden = true
            editGoalButton.isHidden = false
        }

        self.stepGoalTextField.text = ""
        self.stepGoalTextField.resignFirstResponder()
    }
    
    // Handler that transitions to GameViewController upon tapping 'Play Game' button
    @IBAction func tapPlayGameButton(_ sender: UIButton) {
        let gameVC = GameViewController()
        
        // Ensures any arrows unused frm last game are accounted for during this game
        if self.firedArrowsLastGame > 0 {
            gameVC.arrowsAvailable = self.availableArrows
            gameVC.arrowsUsed = self.firedArrowsLastGame
        } else {
            gameVC.arrowsAvailable = self.availableArrows
        }
    
        self.firedArrowsLastGame = 0
        self.navigationController?.pushViewController(gameVC, animated: true)
    }

    // MARK: =====UI Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()

        self.motionModel.delegate = self
        self.motionModel.startActivityMonitoring()
        self.motionModel.startPedometerMonitoring()
        
        // Hides UI elements that should only be shown if step goal is reached
        playGameButton.isHidden = true
        currencyLabel.isHidden = true
        stepGoalTextField.isHidden = true
        saveGoalButton.isHidden = true
        
        // Retrieves step goal from UserDefaults app storage
        // Set step goal to 50 steps if no previously established step goal in UserDefaults app storage
        var savedGoal = UserDefaults.standard.integer(forKey: "stepGoal")
        if savedGoal == 0 {
            savedGoal = 50
            UserDefaults.standard.set(savedGoal, forKey: "stepGoal")
        }
        
        // Build circular step goal progress view and bar chart that will have today's & yesterday's steps
        self.stepGoal = savedGoal
        goalStepLabel.text = "Goal: \(stepGoal)"
        configureCircularProgressBarView()
        configureBarChartView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Sets circular step goal progress view position and size constraints
        circularProgressBarView.frame = CGRect(
            x: view.bounds.midX - 85,
            y: view.bounds.midY - 260,
            width: 170,
            height: 170
        )
    }
    
    // Adds circular step goal progress view to outer UIView and updates progress based on today's steps
    func configureCircularProgressBarView() {
        view.addSubview(circularProgressBarView)
        updateCircularProgressBar()
    }
    
    // Sets up initial DGCharts bar chart parameters
    func configureBarChartView() {
        // No bar chart description or legend
        barChartView.chartDescription.enabled = false
        barChartView.legend.enabled = false
        
        // Configure x-axis (i.e., date data)
        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.xAxis.granularity = 1
        barChartView.xAxis.labelCount = 2

        // Enable y-axis on left axis (and not on right side)
        barChartView.leftAxis.enabled = true
        barChartView.rightAxis.enabled = false
        barChartView.leftAxis.axisMinimum = 0
        barChartView.leftAxis.drawGridLinesEnabled = false
    }
    
    // Change progress towards step goal when real-time step updates arrive for today
    func updateCircularProgressBar() {
        
        // Recalculate amount of game currency if no currency remaining from a last played game
        if self.firedArrowsLastGame == 0 {
            self.availableArrows = Int(todaySteps) / stepGoal
        }
        
        // Show amount of currency (i.e., arrows) to user via update to currency label
        self.currencyLabel.text = "Currency: \(self.availableArrows)"
        
        // Update progress towards the next step goal on circular step goal progress view
        let progress = min(Float(todaySteps) / Float(stepGoal), 1.0)
        circularProgressBarView.setProgress(CGFloat(progress), animated: false)

        // Update the play game button visibility if step goal reached at least once (i.e., 1 currency)
        if self.availableArrows > 0 {
            playGameButton.isHidden = false
            currencyLabel.isHidden = false
        } else {
            playGameButton.isHidden = true
            currencyLabel.isHidden = true
        }
    }
    
    // Handles changes to bar chart based on real-time step updates
    func updateBarChart() {
        let todaySteps: Int = self.todaySteps
        let yesterdaySteps: Int = self.yesterdaySteps

        DispatchQueue.main.async {
            // Include one bar for yesterday's steps and one bar for today's steps
            let entries = [
                BarChartDataEntry(x: 0, y: Double(yesterdaySteps)),
                BarChartDataEntry(x: 1, y: Double(todaySteps))
            ]
            
            // Establish bar chart colors and data label formats
            let dataSet = BarChartDataSet(entries: entries, label: "Steps")
            dataSet.colors = [UIColor.systemBlue]
            dataSet.valueFont = UIFont.systemFont(ofSize: 14)
            dataSet.valueFormatter = IntegerValueFormatter()    // Show data labels without ".0"

            let data = BarChartData(dataSet: dataSet)

            // Calculate yesterday's and today's dates for x-axis
            let todayDate = Date()
            let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: todayDate)!

            // Format dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let todayDateString = dateFormatter.string(from: todayDate)
            let yesterdayDateString = dateFormatter.string(from: yesterdayDate)

            // Set x-axis date labels and settings
            let formatter = BarChartFormatter()
            formatter.labels = [yesterdayDateString, todayDateString]
            self.barChartView.xAxis.valueFormatter = formatter
            self.barChartView.xAxis.granularity = 1
            self.barChartView.xAxis.labelCount = entries.count

            // Adjust y-axis maximum if today's steps exceed prior maximum
            let maxSteps = max(Double(todaySteps), Double(yesterdaySteps))
            self.barChartView.leftAxis.axisMaximum = maxSteps * 1.5 // Increase by 50%

            self.barChartView.data = data
        }
    }
    
    // Records amount of unused game currency from last game (i.e., if not all arrows used in one game)
    func trackLastGame(remainingArrows: Int, arrowsUsedInGame: Int) {
        self.availableArrows = remainingArrows
        self.firedArrowsLastGame = arrowsUsedInGame
        DispatchQueue.main.async {
            self.updateCircularProgressBar()
        }
    }
    
    // Function used when all game currency (i.e., amount of arrows earned) is used during one game
    // Increases step goal by multiple of step goal necessary to achieve 1 arrow for next game
    func resetStepProgress(arrowsUsedInGame: Int) {
        self.stepGoal = self.stepGoal * (arrowsUsedInGame + 1)
        UserDefaults.standard.set(self.stepGoal, forKey: "stepGoal")
        goalStepLabel.text = "Goal: \(self.stepGoal)"
        
        // Ensure currency marker that reflects prior unfinished games when > 0 is reset
        self.firedArrowsLastGame = 0

        DispatchQueue.main.async {
            self.updateCircularProgressBar()
        }
    }
}

extension ViewController: MotionDelegate {
    // MARK: =====Motion Delegate Methods=====
    // Handles UI updates with emojis specific to new activity updates (e.g., walking, running)
    // Emojis are added to label since activities are not necessarily mutually exclusive
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
    
    // Handles UI updates based on receiving real-time step updates for today
    func pedometerUpdatedToday(steps: Float) {
        DispatchQueue.main.async {
            let stepsInt = Int(steps)
            self.todaySteps = stepsInt
            self.todayStepLabel.text = "Today: \(stepsInt)"
            self.updateCircularProgressBar()
            self.updateBarChart()
        }
    }
    
    // Handles UI updates when yesterday's steps are retrieved
    func pedometerUpdatedYesterday(steps: Float) {
        DispatchQueue.main.async {
            let stepsInt = Int(steps)
            self.yesterdaySteps = stepsInt
            self.updateBarChart()
        }
    }
    
    // Helper used in activityUpdated() so that 'if label != "Activity: "' not repeated for each activity
    private func updateActivityLabel(label: inout String, newActivityPresent: Bool, emoji: String) {
        if (newActivityPresent) {
            if label != "Activity: " {
                label += ", "
            }
            label += emoji
        }
    }
}

