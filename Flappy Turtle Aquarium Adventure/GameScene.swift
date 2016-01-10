//
//  GameScene.swift
//  Flappy Turtle Aquarium Adventure
//
//  Created by Bill Crews on 1/7/16.
//  Copyright (c) 2016 BC App Designs, LLC. All rights reserved.
//

import SpriteKit

//MARK: enum's

enum Layer: CGFloat {
  case Background
  case Obstacle
  case Foreground
  case Player
  case UI
  case Flash
}

enum GameState {
  case MainMenu
  case Tutorial
  case Play
  case Falling
  case ShowingScore
  case GameOver
}

struct PhysicsCategory {
  static let None: UInt32 = 0
  static let Player: UInt32 =      0b1   // 1
  static let Obstacle: UInt32 =   0b10   // 2
  static let Ground: UInt32 =    0b100   // 4
}

protocol CustomNodeEvents {
  func didMoveToScene()
}

protocol interactiveNode {
  func interact()
}

class GameScene: SKScene, SKPhysicsContactDelegate {
  
//  var turtleNode: TurtleNode!
//  var groundNode: GroundNode!
  
  var currentLevel: Int = 0
  
  
  override func didMoveToView(view: SKView) {
    
    // Calculate playable margin
    
    let maxAspectRatio:CGFloat = 16.0/9.0  // iPhone5
    let maxAspectRatioHeight = size.height * maxAspectRatio
    let playableMargin:CGFloat = (size.height - maxAspectRatioHeight)/2
    
    let playableRect = CGRect(x: 0, y: playableMargin,
      width: size.width,
      height: size.height - playableMargin * 2)
    
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    /* Called when a touch begins */
    
    for touch in touches {
      let location = touch.locationInNode(self)
      
      let sprite = SKSpriteNode(imageNamed:"Spaceship")
      
      sprite.xScale = 0.5
      sprite.yScale = 0.5
      sprite.position = location
      
      let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
      
      sprite.runAction(SKAction.repeatActionForever(action))
      
      self.addChild(sprite)
    }
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
  
  class func level(levelNum: Int) -> GameScene? {
    let scene = GameScene(fileNamed: "Level\(levelNum)")
    scene?.currentLevel = levelNum
    scene?.scaleMode = .AspectFill
    return scene
  }

}
