//
//  GameScene.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/24/24.
//

import UIKit
import SpriteKit
import CoreMotion

// Delegate for GameViewController that holds SpriteKit GameScene
// Can update GameViewController state (i.e., arrow count) based on arrows fired in game
// Can indicate from in game when to move from GameViewController to ViewController (i.e., step data view)
protocol GameSceneDelegate: AnyObject {
    func useArrow()
    func leaveGameView()
}

// Holds all elements necessary to run SpriteKit bow, arrow, and target game
class GameScene: SKScene, SKPhysicsContactDelegate {

    // Motion manager to access device's gravity readings
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
    var arrowsLabel: SKLabelNode!
    
    var arrowsRemaining: Int = 0    // Remaining arrows to shoot before game over

    // Flags
    var isArrowFired = false    // Prevents uncontrolled arrow firing
    var gameOver = false        // Indicates when to reset game and drop collision rules

    // Physics categories for collision detection
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let arrow: UInt32 = 0b1
        static let target: UInt32 = 0b10
        static let ground: UInt32 = 0b100
    }
    
    // Equivalent to viewDidLoad that sets up initial game environment state
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

        // Shows label with remaining arrows left to fire before game over
        arrowsLabel = SKLabelNode(text: "Arrows: \(arrowsRemaining)")
        arrowsLabel.fontColor = .black
        arrowsLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 280)
        addChild(arrowsLabel)

        // Adds instructional 'Tap To Fire' message
        tapLabel = SKLabelNode(text: "Tap To Fire")
        tapLabel.fontName = "HelveticaNeue-UltraLight"
        tapLabel.fontSize = 24
        tapLabel.fontColor = .black
        tapLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 250)
        addChild(tapLabel)
        
        // Adds instructional 'Rotate To Adjust Gravity' message
        rotateLabel = SKLabelNode(text: "Rotate To Adjust Gravity")
        rotateLabel.fontName = "HelveticaNeue-UltraLight"
        rotateLabel.fontSize = 24
        rotateLabel.fontColor = .black
        rotateLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 210)
        addChild(rotateLabel)

        // Start receiving motion updates
        startMotionUpdates()
    }
    
    // Builds blocks of green ground that arrows could hit on target misses (i.e., a lose condition)
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
    
    // Initializes the bow sprite
    func setupBow() {
        bow = SKSpriteNode(imageNamed: "bow")
        bow.position = CGPoint(x: bow.size.width / 2 + 40, y: ground.size.height + bow.size.height / 2)
        bow.zPosition = 1
        bow.zRotation = CGFloat.pi / 4 // +45 degrees
        addChild(bow)
    }
    
    // Initialize the target sprite
    func setupTarget() {
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

    // Create continuous up and down movement for target to make target hard to hit
    func mobilizeTarget() {
        let moveUp = SKAction.moveBy(x: 0, y: 400, duration: 0.75)
        let moveDown = SKAction.moveBy(x: 0, y: -400, duration: 0.75)
        let sequence = SKAction.sequence([moveUp, moveDown])
        let repeatAction = SKAction.repeatForever(sequence)
        target.run(repeatAction, withKey: "moveAction")
    }
    
    // Fire arrow when finger is lifted from screen (i.e., after tap)
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }
        
        // Do not allow uncontrolled secondary firings after an initial firing
        if isArrowFired { return }
        isArrowFired = true
        fireArrow()
    }
    
    // Creates and assigns physics to arrow that is fired from bow
    func fireArrow() {
        // Remove 'Tap To Fire', 'Rotate To Adjust Gravity', 'Arrows: Num' labels
        tapLabel.removeFromParent()
        rotateLabel.removeFromParent()
        arrowsLabel.removeFromParent()

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

        // Apply impulse to the arrow to account for changes in momentum
        arrow!.physicsBody?.applyImpulse(vector)
        
        // Decrease arrows remaining
        arrowsRemaining -= 1
        gameSceneDelegate?.useArrow()
        arrowsLabel.text = "Arrows: \(arrowsRemaining)"
    }
    
    // Includes functinoality for handling collisions between physics bodies
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

        // Arrow and Target Collision - Win Condition
        if firstBody.categoryBitMask == PhysicsCategory.arrow && secondBody.categoryBitMask == PhysicsCategory.target {
            arrowDidHitTarget()
        }

        // Arrow and Ground Collision - Lose Condition
        else if firstBody.categoryBitMask == PhysicsCategory.arrow && secondBody.categoryBitMask == PhysicsCategory.ground {
            arrowDidNotHitTarget()
        }
    }
    
    // Lodges arrow in target upon successful hit
    // Either resets the game or exits the game depending on remaining arrows
    func arrowDidHitTarget() {
        if gameOver { return }
        gameOver = true

        // Stop the arrow and target
        arrow?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        arrow?.physicsBody = nil // Remove physics body
        target.removeAction(forKey: "moveAction") // Stops target up/down motion upon successful hit
        
        // Exit game (i.e., to step data ViewController) if no remaining arrows
        if arrowsRemaining <= 0 {
            gameOver = true
            showStatusLabel(text: "You Won! Exiting Game...")
            run(SKAction.wait(forDuration: 2)) {
                self.exitGame()
            }
        // Reset the game after a delay if arrows remain
        } else {
            showStatusLabel(text: "You Won! Restarting Game...")
            run(SKAction.wait(forDuration: 2)) {
                self.arrow?.removeFromParent() // Remove arrow
                self.resetGame(isHit: true)
                self.isArrowFired = false
                self.gameOver = false
            }
        }
    }
    
    // Removes arrow from game world upon target miss
    // Either resets the game or exits the game depending on remaining arrows
    func arrowDidNotHitTarget() {
        if gameOver { return }

        // Stop the arrow and target
        arrow?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        arrow?.physicsBody = nil // Remove physics body
        
        // Exit game (i.e., to step data ViewController) if no remaining arrows
        if arrowsRemaining <= 0 {
            gameOver = true
            showStatusLabel(text: "You Lose! Exiting Game...")
            run(SKAction.wait(forDuration: 2)) {
                self.exitGame()
            }
        // Reset the game after a delay if arrows remain
        } else {
            showStatusLabel(text: "You Lose! Restarting Game...")
            run(SKAction.wait(forDuration: 2)) {
                self.arrow?.removeFromParent() // Remove arrow
                self.resetGame(isHit: false)
                self.isArrowFired = false
                self.gameOver = false
            }
        }
    }

    func resetGame(isHit: Bool) {
        // Remove win or loss label upon game reset
        self.childNode(withName: "statusLabelNode")?.removeFromParent()

        // Re-add 'Tap To Fire', 'Rotate To Adjust Gravity', and remaining arrows labels
        addChild(tapLabel)
        addChild(rotateLabel)
        addChild(arrowsLabel)

        // Reset flag variables
        isArrowFired = false
        gameOver = false
        
        // Restart target position and movement if successful hit
        // Necessary because target motion is stopped upon successful hit in arrowDidHitTarget()
        if (isHit) {
            target.position = CGPoint(x: size.width - target.size.width / 2 - 20,
                                      y: ground.size.height + target.size.height / 2)
            target.zPosition = 1
            mobilizeTarget()
        }
    }
    
    // Stops motion (e.g., gravity updates) and returns to step data ViewController
    func exitGame() {
        motionManager.stopDeviceMotionUpdates()
        gameSceneDelegate?.leaveGameView()
    }
    
    // Adds a status label node with specified text to game environment
    func showStatusLabel(text: String) {
        let label = SKLabelNode(text: text)
        label.name = "statusLabelNode"
        label.fontColor = .black
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 250)
        label.zPosition = 2
        addChild(label)
    }
    
    // Begins motion (e.g., gravity reading) updates
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable && !motionManager.isDeviceMotionActive {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion else { return }
                self.updateGravity(motion)
            }
        }
    }
    
    // Updates game world gravity based on gravity readings on phone's X and Y axes
    // Y-axis gravity reading updates most important for this game (i.e., vertical force on fired arrow)
    func updateGravity(_ motion: CMDeviceMotion) {
        let gravity = motion.gravity
        let gravityScale = 9.8
        let dx = gravity.x * gravityScale
        let dy = gravity.y * gravityScale

        self.physicsWorld.gravity = CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
    }
    
    // Primarily for handling effects on traveling arrow fired from bow for this game
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
                arrowDidNotHitTarget()
            }
        }
    }
}

