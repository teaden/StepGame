import UIKit
import SpriteKit
import CoreMotion

protocol GameSceneDelegate: AnyObject {
    func useArrow()
    func leaveGameView()
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
    var arrowsLabel: SKLabelNode!

    // Remaining arrows to shoot before game over
    var arrowsRemaining: Int = 0
    var initialArrowsCount: Int = 0 // Added to keep track of initial arrows

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

        // Set up arrows remaining label
        arrowsLabel = SKLabelNode(text: "Arrows: \(arrowsRemaining)")
        arrowsLabel.fontColor = .black
        arrowsLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 280)
        addChild(arrowsLabel)

        // Add 'Tap To Fire' message
        tapLabel = SKLabelNode(text: "Tap To Fire")
        tapLabel.fontName = "HelveticaNeue-UltraLight"
        tapLabel.fontSize = 24
        tapLabel.fontColor = .black
        tapLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 250)
        addChild(tapLabel)

        rotateLabel = SKLabelNode(text: "Rotate To Adjust Gravity")
        rotateLabel.fontName = "HelveticaNeue-UltraLight"
        rotateLabel.fontSize = 24
        rotateLabel.fontColor = .black
        rotateLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 210)
        addChild(rotateLabel)

        // Record the initial number of arrows
        initialArrowsCount = arrowsRemaining

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
        // Remove existing movement action if any
        target.removeAction(forKey: "moveAction")
        
        // Create up and down movement
        let moveUp = SKAction.moveBy(x: 0, y: 400, duration: 0.75)
        let moveDown = SKAction.moveBy(x: 0, y: -400, duration: 0.75)
        let sequence = SKAction.sequence([moveUp, moveDown])
        let repeatAction = SKAction.repeatForever(sequence)
        target.run(repeatAction, withKey: "moveAction")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }

        if isArrowFired { return } // Remove gameOver check to allow immediate firing

        isArrowFired = true
        fireArrow()
    }

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

        // Apply impulse to the arrow
        arrow!.physicsBody?.applyImpulse(vector)
        
        // Decrease arrows remaining
        arrowsRemaining -= 1
        gameSceneDelegate?.useArrow()
        arrowsLabel.text = "Arrows: \(arrowsRemaining)"
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
            arrowDidNotHitTarget()
        }
    }

    func arrowDidHitTarget() {
        if gameOver { return }
        gameOver = true

        // Stop the arrow and target
        arrow?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        arrow?.physicsBody = nil // Remove physics body
        target.removeAction(forKey: "moveAction")
        
        if arrowsRemaining <= 0 {
            gameOver = true
            showStatusLabel(text: "You Won! Exiting Game...")
            run(SKAction.wait(forDuration: 2)) {
                self.exitGame()
            }
        } else {
            // Reset the game after a delay
            showStatusLabel(text: "You Won! Restarting Game...")
            run(SKAction.wait(forDuration: 2)) {
                self.arrow?.removeFromParent() // Remove arrow
                self.resetGame(isHit: true)
                self.isArrowFired = false
                self.gameOver = false
            }
        }
    }

    func arrowDidNotHitTarget() {
        if gameOver { return }

        // Stop the arrow and target
        arrow?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        arrow?.physicsBody = nil // Remove physics body

        if arrowsRemaining <= 0 {
            // No arrows left, game over
            gameOver = true
            showStatusLabel(text: "You Lose! Exiting Game...")
            run(SKAction.wait(forDuration: 2)) {
                self.exitGame()
            }
        } else {
            // Reset the game after a delay
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
        // Remove arrow and labels
        arrow?.removeFromParent()
        self.childNode(withName: "statusLabelNode")?.removeFromParent()

        // Re-add 'Tap To Fire' and 'Rotate To Adjust Gravity' labels
        addChild(tapLabel)
        addChild(rotateLabel)
        addChild(arrowsLabel)

        // Reset variables
        isArrowFired = false
        gameOver = false
        
        if (isHit) {
            // Restart target position and movement
            target.position = CGPoint(x: size.width - target.size.width / 2 - 20,
                                      y: ground.size.height + target.size.height / 2)
            target.zPosition = 1
            mobilizeTarget()
        }
    }

    func exitGame() {
        motionManager.stopDeviceMotionUpdates()
        gameSceneDelegate?.leaveGameView()
    }

    func showStatusLabel(text: String) {
        // Show lose message
        let label = SKLabelNode(text: text)
        label.name = "statusLabelNode"
        label.fontColor = .black
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 250)
        label.zPosition = 2
        addChild(label)
    }

    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable && !motionManager.isDeviceMotionActive {
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
                arrowDidNotHitTarget()
            }
        }
    }
}

