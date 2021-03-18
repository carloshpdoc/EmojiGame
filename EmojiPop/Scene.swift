//
//  Scene.swift
//  EmojiPop
//
//  Created by Carlos Henrique on 17/03/21.
//

import SpriteKit
import ARKit

public enum GameState {
  case Init
  case TapToStart
  case Playing
  case GameOver
}

class Scene: SKScene {
    
    var gameState = GameState.Init
    var anchor: ARAnchor?
    var emojis = "😁😂😛😝😋😜🤪😎🤓🤖🎃💀🤡"
    var spawnTime : TimeInterval = 0
    var score : Int = 0
    var lives : Int = 10

    override func didMove(to view: SKView) {
        // Setup your scene here
        startGame()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState != .Playing { return }
        if spawnTime == 0 { spawnTime = currentTime + 3 }
        if spawnTime < currentTime {
          spawnEmoji()
          spawnTime = currentTime + 0.5;
        }

        updateHUD("SCORE: " + String(score) +
          " | LIVES: " + String(lives))

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sceneView = self.view as? ARSKView else {
            return
        }
        
        switch (gameState)
        {
          case .Init:
            break
              
          case .TapToStart:
            playGame()
            break
              
          case .Playing:
            checkTouches(touches)
            break
              
          case .GameOver:
            startGame()
            break
        }

    }
    
    func updateHUD(_ message: String) {
      guard let sceneView = self.view as? ARSKView else {
        return
      }
      let viewController = sceneView.delegate as! ViewController
        viewController.hudLabel.text = message
    }

    func addAnchor() {

      guard let sceneView = self.view as? ARSKView else {
        return
      }

      if let currentFrame = sceneView.session.currentFrame {

        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.5
        let transform = simd_mul(currentFrame.camera.transform, translation)

        anchor = ARAnchor(transform: transform)
        sceneView.session.add(anchor: anchor!)
      }
    }
    
    public func startGame() {
      removeAnchor()

      gameState = .TapToStart
      updateHUD("- TAP TO START -")
    }

    public func playGame() {
      gameState = .Playing
      score = 0
      lives = 10
      spawnTime = 0
    
      addAnchor()

    }

    public func stopGame() {
      gameState = .GameOver
      updateHUD("GAME OVER! SCORE: " + String(score))
    }

    func removeAnchor() {
      guard let sceneView = self.view as? ARSKView else {
        return
      }
      if anchor != nil {
        sceneView.session.remove(anchor: anchor!)
      }
    }
    
    func spawnEmoji() {

      let emojiNode = SKLabelNode(text:String(emojis.randomElement()!))
      emojiNode.name = "Emoji"
      emojiNode.horizontalAlignmentMode = .center
      emojiNode.verticalAlignmentMode = .center

      guard let sceneView = self.view as? ARSKView else { return }
      let spawnNode = sceneView.scene?.childNode(
        withName: "SpawnPoint")
      spawnNode?.addChild(emojiNode)
        
    
        // Enable Physics
        emojiNode.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        emojiNode.physicsBody?.mass = 0.01

        // Add Impulse
        emojiNode.physicsBody?.applyImpulse(CGVector(
          dx: -5 + 10 * randomCGFloat(), dy: 10))

        // Add Torque
        emojiNode.physicsBody?.applyTorque(-0.2 + 0.4 * randomCGFloat())

        let spawnSoundAction = SKAction.playSoundFileNamed("SoundEffects/Spawn.wav", waitForCompletion: false)
        let dieSoundAction = SKAction.playSoundFileNamed("SoundEffects/Die.wav", waitForCompletion: false)
        let waitAction = SKAction.wait(forDuration: 3)
        let removeAction = SKAction.removeFromParent()

        let runAction = SKAction.run({
          self.lives -= 1
          if self.lives <= 0 {
            self.stopGame()
          }
        })

        let sequenceAction = SKAction.sequence([spawnSoundAction, waitAction, dieSoundAction, runAction, removeAction])
        emojiNode.run(sequenceAction)

    }

    func checkTouches(_ touches: Set<UITouch>) {

      guard let touch = touches.first else { return }
      let touchLocation = touch.location(in: self)
      let touchedNode = self.atPoint(touchLocation)

      if touchedNode.name != "Emoji" { return }
      score += 1

      let collectSoundAction = SKAction.playSoundFileNamed("SoundEffects/Collect.wav", waitForCompletion: false)
      let removeAction = SKAction.removeFromParent()
      let sequenceAction = SKAction.sequence(
        [collectSoundAction, removeAction])
      touchedNode.run(sequenceAction)
    }

    func randomCGFloat() -> CGFloat {
      return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
    }

}
