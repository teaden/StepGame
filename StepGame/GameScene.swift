//
//  GameScene.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/24/24.
//

import UIKit
import SpriteKit
import CoreMotion

protocol GameSceneDelegate: AnyObject {
    func gameDidEnd()
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Motion manager to access device's motion data
    let motionManager = CMMotionManager()
    weak var gameSceneDelegate: GameSceneDelegate?
    
    // Sprites
    var bow: SKSpriteNode!
    var arrow: SKSpriteNode?
    var target: SKSpriteNode!
    var ground: SKSpriteNode!
    var trajectoryLine: SKShapeNode!
    
    // Labels
    var tapLabel: SKLabelNode!
    var rotateLabel: SKLabelNode!
    
    // Flags
    var isArrowFired = false
    var gameOver = false
    
    // Physics categories for collision detection
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let arrow: UInt32 = 0b1      // 1
        static let target: UInt32 = 0b10    // 2
        static let ground: UInt32 = 0b100   // 4
    }
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        // Set the background color to blue
        self.backgroundColor = SKColor.cyan
        
        // Set up the ground
        setupGround()
        
        // Set up the bow
        setupBow()
        
        // Set up the target
        setupTarget()
        
        // Add 'Tap To Fire' message
        tapLabel = SKLabelNode(text: "Tap To Fire")
        tapLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 250)
        tapLabel.fontColor = .black
        addChild(tapLabel)

        rotateLabel = SKLabelNode(text: "Rotate To Adjust Gravity")
        rotateLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 210)
        rotateLabel.fontColor = .black
        addChild(rotateLabel)
        
        // Start receiving motion updates
        startMotionUpdates()
    }
    
    func setupGround() {
        ground = SKSpriteNode(color: SKColor.green, size: CGSize(width: size.width, height: 50))
        ground.position = CGPoint(x: size.width / 2, y: ground.size.height / 2)
        ground.zPosition = 1
        
        // Set up physics body for the ground
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.contactTestBitMask = PhysicsCategory.arrow
        ground.physicsBody?.collisionBitMask = PhysicsCategory.arrow
        ground.physicsBody?.isDynamic = false
        
        addChild(ground)
    }
    
    func setupBow() {
        // Initialize the bow sprite
        bow = SKSpriteNode(imageNamed: "bow")
        bow.position = CGPoint(x: bow.size.width / 2 + 40, y: ground.size.height + bow.size.height / 2)
        bow.zPosition = 1
        bow.zRotation = CGFloat.pi / 4 // +45 degrees
        addChild(bow)
    }
    
    func setupTarget() {
        // Initialize the target sprite
        target = SKSpriteNode(imageNamed: "target")
        target.position = CGPoint(x: size.width - target.size.width / 2 - 20, y: ground.size.height + target.size.height / 2)
        target.zPosition = 1
        
        // Set up physics body for the target
        target.physicsBody = SKPhysicsBody(circleOfRadius: target.size.width / 2)
        target.physicsBody?.categoryBitMask = PhysicsCategory.target
        target.physicsBody?.contactTestBitMask = PhysicsCategory.arrow
        target.physicsBody?.collisionBitMask = PhysicsCategory.none
        target.physicsBody?.isDynamic = false
        
        addChild(target)
        mobilizeTarget()
    }
    
    // Create up and down movement
    func mobilizeTarget() {
        // Create up and down movement
        let moveUp = SKAction.moveBy(x: 0, y: 400, duration: 0.75)
        let moveDown = SKAction.moveBy(x: 0, y: -400, duration: 0.75)
        let sequence = SKAction.sequence([moveUp, moveDown])
        let repeatAction = SKAction.repeatForever(sequence)
        target.run(repeatAction)
    }
        
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }

        if isArrowFired || gameOver { return } // Prevent multiple arrows or firing after game over

        isArrowFired = true
        fireArrow()
    }
    
    func fireArrow() {
        // Remove 'Tap To Fire' label
        tapLabel.removeFromParent()
        rotateLabel.removeFromParent()
                
        // Create the arrow sprite
        arrow = SKSpriteNode(imageNamed: "arrow")
        arrow!.position = CGPoint(
            x: bow.position.x + (bow.size.height / 2) * cos(bow.zRotation),
            y: bow.position.y + (bow.size.height / 2) * sin(bow.zRotation)
        )
        arrow!.zRotation = bow.zRotation
        arrow!.zPosition = 1

        // Set up physics body for the arrow
        arrow!.physicsBody = SKPhysicsBody(rectangleOf: arrow!.size)
        arrow!.physicsBody?.categoryBitMask = PhysicsCategory.arrow
        arrow!.physicsBody?.contactTestBitMask = PhysicsCategory.target | PhysicsCategory.ground
        arrow!.physicsBody?.collisionBitMask = PhysicsCategory.ground
        arrow!.physicsBody?.usesPreciseCollisionDetection = true
        arrow!.physicsBody?.allowsRotation = true

        addChild(arrow!)

        // Calculate the force vector
        let dx = cos(bow.zRotation)
        let dy = sin(bow.zRotation)
        let vector = CGVector(dx: dx * 6, dy: dy * 6)

        // Apply impulse to the arrow
        arrow!.physicsBody?.applyImpulse(vector)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameOver { return } // Ignore collisions after game over
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // Determine which body is which
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Arrow and Target Collision
        if firstBody.categoryBitMask == PhysicsCategory.arrow && secondBody.categoryBitMask == PhysicsCategory.target {
            arrowDidHitTarget()
        }
        
        // Arrow and Ground Collision
        else if firstBody.categoryBitMask == PhysicsCategory.arrow && secondBody.categoryBitMask == PhysicsCategory.ground {
            arrowDidHitGround()
        }
    }
    
    func arrowDidHitTarget() {
        if gameOver { return }
        gameOver = true
        
        // Show win message
        let winLabel = SKLabelNode(text: "You Win! Resetting Game...")
        winLabel.name = "winLabel"
        winLabel.fontColor = .black
        winLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 250)
        winLabel.zPosition = 2
        addChild(winLabel)
        
        // Stop the arrow and target
        arrow?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        arrow?.physicsBody = nil // Remove physics body
        arrow?.removeFromParent() // Remove arrow
        
        target.removeAllActions()
        
        // Reset the game after a delay
        run(SKAction.wait(forDuration: 2)) {
            self.resetGame()
        }
    }
    
    func arrowDidHitGround() {
        if gameOver { return }
        gameOver = true
        
        showLoseLabel()
        
        // Remove the arrow
        arrow?.removeFromParent()
        
        loseGame()
    }
    
    func arrowDidGoOutOfBounds() {
        if gameOver { return }
        gameOver = true
        
        showLoseLabel()
        
        // Remove the arrow
        arrow?.removeFromParent()
        
        loseGame()
    }
    
    func resetGame() {
        // Remove arrow and labels
        arrow?.removeFromParent()
        self.childNode(withName: "winLabel")?.removeFromParent()
        self.childNode(withName: "loseLabel")?.removeFromParent()
        
        // Reset variables
        isArrowFired = false
        gameOver = false
        target.removeAllActions()
                
        // Re-add 'Tap To Fire' label
        addChild(tapLabel)
        addChild(rotateLabel)
        
        // Restart target position and movement
        target.position = CGPoint(x: size.width - target.size.width / 2 - 20, y: ground.size.height + target.size.height / 2)
        target.zPosition = 1
        mobilizeTarget()
    }
    
    func loseGame() {
        motionManager.stopDeviceMotionUpdates()
        gameSceneDelegate?.gameDidEnd()
    }
    
    func showLoseLabel() {
        // Show lose message
        let loseLabel = SKLabelNode(text: "You Lose! Exiting Game...")
        loseLabel.name = "loseLabel"
        loseLabel.fontColor = .black
        loseLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 250)
        loseLabel.zPosition = 2
        addChild(loseLabel)
    }
    
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion else { return }
                self.updateGravity(motion)
            }
        }
    }
    
    func updateGravity(_ motion: CMDeviceMotion) {
        let gravity = motion.gravity

        // Scale the gravity to match Earth's gravity
        let gravityScale = 9.8
        let dx = gravity.x * gravityScale
        let dy = gravity.y * gravityScale

        self.physicsWorld.gravity = CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Update the arrow's rotation to match its velocity
        if let arrow = self.arrow, let velocity = arrow.physicsBody?.velocity {
            if velocity.dx != 0 || velocity.dy != 0 {
                // Calculate the angle based on the velocity vector
                let angle = atan2(velocity.dy, velocity.dx)
                arrow.zRotation = angle
            }
            
            // Check if the arrow is out of bounds
            if !self.frame.contains(arrow.position) {
                arrowDidGoOutOfBounds()
            }
        }
    }
}

