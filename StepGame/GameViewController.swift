//
//  GameViewController.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/24/24.
//

import UIKit
import SpriteKit

// Houses SpriteKit GameScene
// Intermediary state between step data ViewController and SpriteKit GameScene
class GameViewController: UIViewController {
    
    // Available arrows or game currency based step data
    var arrowsAvailable: Int = 0
    
    // Number of arrows fired
    // Important for recording arrows used from a previous game
    // E.g., if user navigates back to step data ViewController before firing all available arrows
    var arrowsUsed: Int = 0
    
    // Flag that indicates if GameViewController popped from navigation stack
    // Ensures viewWillDisappear does not repeat certain exit functionality if another function triggered pop
    var hasPopped: Bool = false

    override func loadView() {
        // Programatically creates an SKView and set it as the view controller's view
        self.view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else {
            fatalError("View of GameViewController is not an SKView")
        }
        
        // Build SpriteKit GameScene and specify related parameters
        let scene = GameScene(size: skView.bounds.size)
        scene.gameSceneDelegate = self
        scene.arrowsRemaining = self.arrowsAvailable
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Proceed only if GameSceneDelegate leaveGameView has not triggered navigation stack pop
        if !self.hasPopped {
            // Record arrows unused from last game session if user exited early
            if self.arrowsAvailable != 0 {
                if let parentVC = self.navigationController?.viewControllers.first(where: { $0 is ViewController }) as? ViewController {
                    parentVC.trackLastGame(remainingArrows: arrowsAvailable, arrowsUsedInGame: arrowsUsed)
                }
                
            // Indicates game ended normally, i.e., user fired all arrows
            // Increases step goal by multiple of step goal necessary to achieve 1 arrow for next game
            // Accounts for case when user presses 'back' immediately after firing last arrow
            } else {
                if let parentVC = self.navigationController?.viewControllers.first(where: { $0 is ViewController }) as? ViewController {
                    parentVC.resetStepProgress(arrowsUsedInGame: self.arrowsUsed)
                }
            }
        }
    }
}

// Conform to the GameSceneDelegate protocol
extension GameViewController: GameSceneDelegate {
    
    // Indicates that an arrow has been fired during the game session
    func useArrow() {
        self.arrowsAvailable -= 1
        self.arrowsUsed += 1
    }
    
    // Pops GameViewController from navigation stack when user runs out of arrows
    // This is as opposed to pressing 'back' button on navbar with arrows remaining
    func leaveGameView() {
        
        // Increases step goal by multiple of step goal necessary to achieve 1 arrow for next game
        if let parentVC = self.navigationController?.viewControllers.first(where: { $0 is ViewController }) as? ViewController {
            parentVC.resetStepProgress(arrowsUsedInGame: self.arrowsUsed)
        }
        
        // Pop the GameViewController
        DispatchQueue.main.async {
            guard !self.hasPopped else { return }
            self.hasPopped = true
            self.navigationController?.popViewController(animated: true)
        }
    }
}

