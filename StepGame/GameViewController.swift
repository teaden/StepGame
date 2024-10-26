//
//  GameViewController.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/24/24.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    var arrowsAvailable: Int = 0
    var arrowsUsed: Int = 0
    var hasPopped: Bool = false

    override func loadView() {
        // Create an SKView and set it as the view controller's view
        self.view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else {
            fatalError("View of GameViewController is not an SKView")
        }

        let scene = GameScene(size: skView.bounds.size)
        scene.gameSceneDelegate = self
        scene.arrowsRemaining = self.arrowsAvailable

        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !self.hasPopped {
            if self.arrowsAvailable != 0 {
                // User exited early
                if let parentVC = self.navigationController?.viewControllers.first(where: { $0 is ViewController }) as? ViewController {
                    parentVC.trackLastGame(remainingArrows: arrowsAvailable, arrowsUsedInGame: arrowsUsed)
                }
            } else {
                // Game ended normally, reset step progress
                if let parentVC = self.navigationController?.viewControllers.first(where: { $0 is ViewController }) as? ViewController {
                    parentVC.resetStepProgress(arrowsUsedInGame: self.arrowsUsed)
                }
            }
        }
    }
}

// Conform to the GameSceneDelegate protocol
extension GameViewController: GameSceneDelegate {
    
    func useArrow() {
        self.arrowsAvailable -= 1
        self.arrowsUsed += 1
    }

    func leaveGameView() {
        // Notify the ViewController to reset step progress
        if let parentVC = self.navigationController?.viewControllers.first(where: { $0 is ViewController }) as? ViewController {
            parentVC.resetStepProgress(arrowsUsedInGame: self.arrowsUsed)
        }
        // Then pop the GameViewController
        DispatchQueue.main.async {
            guard !self.hasPopped else { return }
            self.hasPopped = true
            self.navigationController?.popViewController(animated: true)
        }
    }
}

