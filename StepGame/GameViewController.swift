//
//  GameViewController.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/24/24.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    var hasPopped = false

    override func viewDidLoad() {
        super.viewDidLoad()

        //setup game scene
        let scene = GameScene(size: view.bounds.size)
        scene.gameSceneDelegate = self
        let skView = view as! SKView // the view in storyboard must be an SKView
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Set hasPopped to true if the user navigates back manually
        hasPopped = true
    }
}


// Conform to the GameSceneDelegate protocol
extension GameViewController: GameSceneDelegate {
    // Implement the delegate method
    func gameDidEnd() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard !self.hasPopped else { return }
            self.hasPopped = true
            self.navigationController?.popViewController(animated: true)
        }
    }
}
