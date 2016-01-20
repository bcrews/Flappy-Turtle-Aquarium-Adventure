//
//  GameScene.swift
//  Flappy Turtle Aquarium Adventure
//
//  Created by Bill Crews on 1/7/16.
//  Copyright (c) 2016 BC App Designs, LLC. All rights reserved.
//

import SpriteKit
import iAd
import GameKit

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

protocol GameSceneDelegate {
  
  func screenShot() -> UIImage
  func shareString(string: String, url: NSURL, image: UIImage)
}


class GameScene: SKScene, SKPhysicsContactDelegate, ADBannerViewDelegate, GKGameCenterControllerDelegate {
  
  // MARK: Constants
  
  var Gravity: CGFloat = -1500.0
  let kImpluse: CGFloat =  600.0
  let kNumBackgrounds = 4
  let kNumForegrounds = 2
  let kNumTopObstacles = 23
  let kNumBottomObstacles = 0  // not used in this version
  let kGroundSpeed: CGFloat = 300.0 // 150.0
  let kBackgroundSpeed: CGFloat = 50.0
  let kBottomObstacleMinFraction: CGFloat = 0.05 // 5%
  let kBottomObstacleMaxFraction: CGFloat = 0.585 // 58.5%
  let kGapMultiplier: CGFloat = 1.50
  let kFirstSpawnDelay: NSTimeInterval = 1.75
  let kEverySpawnDelay: NSTimeInterval = 2.5  // 4.75
  let kFontName = "AmericanTypewriter-Bold"
  let kScoreFontSize: CGFloat = 110
  let kMargin: CGFloat = 24.0
  let kAnimDelay = 0.3
  let kNumPlayerFrames = 12
  let kNumTopObstacleFrames = 24
  let kMinDegrees: CGFloat = -90
  let kMaxDegrees: CGFloat =  12
  let kAngularVelocity: CGFloat = 200.0
  
  // App ID
  let kAppStoreID = 934492427
  let kLeaderboardID: String = "grp.com.BCAppDesigns.FlappyTurtleAA"
  
  
  // MARK: Variables
  
  let worldNode = SKNode()
  var playableStart:  CGFloat = 0
  var playableHeight: CGFloat = 0
  var player = SKSpriteNode(imageNamed: "Turtle_Universal_0")
  var topObstacle = SKSpriteNode(imageNamed: "JellyFish_Universal_0")
  var aspectRatio: CGFloat = 0
  var obstacleScaleFactor: CGFloat = 1.3 // 1.2 - 1.5
  var currentLevel: Int = 0
  var lastUpdateTime: NSTimeInterval = 0
  var dt: NSTimeInterval = 0
  var playerVelocity = CGPoint.zero
  //  let playerHat = SKSpriteNode(imageNamed: "hat-christmas")
  let playerHat = SKSpriteNode(imageNamed: "")
  var hitGround: Bool = false
  var hitObstacle: Bool = false
  var gameState: GameState = .Tutorial
  var scoreLabel: SKLabelNode!
  var scoreLabelBackground: SKLabelNode!
  var score = 0
  var gameSceneDelegate: GameSceneDelegate
  var playerAngularVelocity: CGFloat = 0.0
  var lastTouchTime: NSTimeInterval = 0
  var lastTouchY: CGFloat = 0.0
  var gameCenterAchievements = [String: GKAchievement]()  // Achievements Dictionary
  var achievementPercent:Double = 0
  
  
  // MARK: Sounds
  
  let dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
  let flapAction = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
  let whackAction = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
  let fallingAction = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
  let hitGroundAction = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
  let popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
  let coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
  
  
  // Override init to
  init(size: CGSize, delegate:GameSceneDelegate, gameState: GameState) {
    
    self.gameSceneDelegate = delegate
    
    // Set Initial GameState
    self.gameState = gameState
    
    super.init(size: size)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  // MARK: didMoveToView
  
  override func didMoveToView(view: SKView) {
    
    // authenticate Player with Game Center
    authenticateLocalPlayer()
    
    // Turn off gravity
    physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    
    // Register as contactDelegate
    physicsWorld.contactDelegate = self
    
    
    // Create a worldNode to chain everything to
    addChild(worldNode)
    
    //    // Start setups
    //    setupBackground()
    //    setupForeground()
    //    setupPlayer()
    //    //    setupPlayerHat()
    //
    //    // Start spawning objects
    //    startSpawning()
    //
    //    // Setup Label (Score)
    //    setupLabel()
    //
    //    // Give player a free flap to start
    //    flapPlayer()
    
    if gameState == .MainMenu {
      switchToMainMenu()
    } else {
      switchToTutorial()
    }
  }
  
  
  // MARK: Setup methods
  
  func setupBackground() {
    
    for i in 0..<kNumBackgrounds {
      
      let background = SKSpriteNode(imageNamed: "Aquarium_BG_Universal_\(i)")
      
      background.anchorPoint = CGPoint(x: 0.5, y: 1.0)
      background.position = CGPoint(x: CGFloat(i) * size.width, y: size.height)
      background.zPosition = Layer.Background.rawValue
      background.name = "background"
      
      let lowerLeft = CGPoint(x: 0, y: playableStart)
      let lowerRight = CGPoint(x: size.width, y: playableStart)
      
      self.physicsBody = SKPhysicsBody(edgeFromPoint: lowerLeft, toPoint: lowerRight)
      self.physicsBody?.categoryBitMask = PhysicsCategory.Ground
      self.physicsBody?.collisionBitMask = 0
      self.physicsBody?.contactTestBitMask = PhysicsCategory.Player
      worldNode.addChild(background)
      
      playableStart = size.height - background.size.height
      playableHeight = background.size.height
      
      // print("Background size: \(background.size)")
      
    }
  }
  
  func setupForeground() {
    
    for i in 0..<kNumForegrounds {
      let foreground = SKSpriteNode(imageNamed: "Ground_Universal")
      foreground.anchorPoint = CGPoint(x: 0, y: 1)
      foreground.position = CGPoint(x: CGFloat(i) * size.width, y: playableStart)
      foreground.zPosition = Layer.Foreground.rawValue
      foreground.name = "foreground"
      worldNode.addChild(foreground)
    }
  }
  
  func setupPlayer() {
    
    aspectRatio = size.height / size.width
    //  print("AspectRatio = \(aspectRatio)")
    
    player.position = CGPoint(x: (size.width * 0.20) * aspectRatio, y: playableHeight * 0.4 + playableStart)
    player.zPosition = Layer.Player.rawValue
    let offsetX = player.size.width * player.anchorPoint.x
    let offsetY = player.size.height * player.anchorPoint.y
    
    let path = CGPathCreateMutable()
    
    CGPathMoveToPoint(path, nil, 100 - offsetX, 143 - offsetY)
    CGPathAddLineToPoint(path, nil, 71 - offsetX, 136 - offsetY)
    CGPathAddLineToPoint(path, nil, 50 - offsetX, 105 - offsetY)
    CGPathAddLineToPoint(path, nil, 38 - offsetX, 88 - offsetY)
    CGPathAddLineToPoint(path, nil, 16 - offsetX, 96 - offsetY)
    CGPathAddLineToPoint(path, nil, 37 - offsetX, 80 - offsetY)
    CGPathAddLineToPoint(path, nil, 48 - offsetX, 79 - offsetY)
    CGPathAddLineToPoint(path, nil, 53 - offsetX, 72 - offsetY)
    CGPathAddLineToPoint(path, nil, 14 - offsetX, 77 - offsetY)
    CGPathAddLineToPoint(path, nil, 13 - offsetX, 61 - offsetY)
    CGPathAddLineToPoint(path, nil, 39 - offsetX, 40 - offsetY)
    CGPathAddLineToPoint(path, nil, 72 - offsetX, 47 - offsetY)
    CGPathAddLineToPoint(path, nil, 86 - offsetX, 60 - offsetY)
    CGPathAddLineToPoint(path, nil, 129 - offsetX, 65 - offsetY)
    CGPathAddLineToPoint(path, nil, 127 - offsetX, 60 - offsetY)
    CGPathAddLineToPoint(path, nil, 99 - offsetX, 36 - offsetY)
    CGPathAddLineToPoint(path, nil, 96 - offsetX, 19 - offsetY)
    CGPathAddLineToPoint(path, nil, 109 - offsetX, 16 - offsetY)
    CGPathAddLineToPoint(path, nil, 130 - offsetX, 22 - offsetY)
    CGPathAddLineToPoint(path, nil, 146 - offsetX, 32 - offsetY)
    CGPathAddLineToPoint(path, nil, 150 - offsetX, 23 - offsetY)
    CGPathAddLineToPoint(path, nil, 163 - offsetX, 29 - offsetY)
    CGPathAddLineToPoint(path, nil, 173 - offsetX, 56 - offsetY)
    CGPathAddLineToPoint(path, nil, 162 - offsetX, 96 - offsetY)
    CGPathAddLineToPoint(path, nil, 185 - offsetX, 111 - offsetY)
    CGPathAddLineToPoint(path, nil, 215 - offsetX, 95 - offsetY)
    CGPathAddLineToPoint(path, nil, 247 - offsetX, 100 - offsetY)
    CGPathAddLineToPoint(path, nil, 241 - offsetX, 113 - offsetY)
    CGPathAddLineToPoint(path, nil, 262 - offsetX, 118 - offsetY)
    CGPathAddLineToPoint(path, nil, 256 - offsetX, 152 - offsetY)
    CGPathAddLineToPoint(path, nil, 232 - offsetX, 172 - offsetY)
    CGPathAddLineToPoint(path, nil, 203 - offsetX, 176 - offsetY)
    CGPathAddLineToPoint(path, nil, 171 - offsetX, 167 - offsetY)
    CGPathAddLineToPoint(path, nil, 164 - offsetX, 144 - offsetY)
    CGPathAddLineToPoint(path, nil, 168 - offsetX, 122 - offsetY)
    CGPathAddLineToPoint(path, nil, 160 - offsetX, 112 - offsetY)
    CGPathAddLineToPoint(path, nil, 131 - offsetX, 138 - offsetY)
    
    CGPathCloseSubpath(path)
    
    player.physicsBody = SKPhysicsBody(polygonFromPath: path)
    player.physicsBody?.categoryBitMask = PhysicsCategory.Player
    player.physicsBody?.collisionBitMask = 0
    player.physicsBody?.contactTestBitMask = PhysicsCategory.Obstacle | PhysicsCategory.Ground
    
    //   print("Player Size: \(player.size)")
    //   print("AspectRatio: \(aspectRatio)")
    
    player.xScale *= aspectRatio
    player.yScale *= aspectRatio
    
    worldNode.addChild(player)
    
    
    
  }
  
  func setupPlayerHat() {
    
    let playerHat = SKSpriteNode(imageNamed: "hat-christmas")
    playerHat.position = CGPoint(x: 95 - playerHat.size.width/2, y: 128 - playerHat.size.height/2)
    player.addChild(playerHat)
    
  }
  
  func setupLabel() {
    
    scoreLabel = SKLabelNode(fontNamed: kFontName)
    scoreLabel.fontColor = SKColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    scoreLabel.position = CGPoint(x: size.width/2, y: size.height - kMargin)
    scoreLabel.text = "0"
    scoreLabel.verticalAlignmentMode = .Top
    scoreLabel.zPosition = Layer.UI.rawValue
    scoreLabel.fontSize = kScoreFontSize
    worldNode.addChild(scoreLabel)
    
    scoreLabelBackground = SKLabelNode(fontNamed: kFontName)
    scoreLabelBackground.fontColor = SKColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    scoreLabelBackground.position = CGPoint(x: size.width/2 + 5, y: size.height - kMargin - 5)
    scoreLabelBackground.text = scoreLabel.text
    scoreLabelBackground.verticalAlignmentMode = .Top
    scoreLabelBackground.zPosition = scoreLabel.zPosition - 1
    scoreLabelBackground.fontSize = kScoreFontSize
    worldNode.addChild(scoreLabelBackground)
    
  }
  
  func setupScorecard() {
    
    if score > bestScore() {
      setBestScore(score)
      
      // update GameCenter
      self.saveHighScore(kLeaderboardID, score: bestScore())
    }
    
    let scorecard = SKSpriteNode(imageNamed: NSLocalizedString("ScoreCardImageName", comment: "ScoreCard Image Name"))
    scorecard.position = CGPoint(x: size.width * 0.5, y: size.height * 0.60)
    scorecard.xScale *= 1.0 / aspectRatio
    scorecard.yScale *= 1.0 / aspectRatio
    scorecard.name = "Tutorial"
    scorecard.zPosition = Layer.UI.rawValue
    worldNode.addChild(scorecard)
    
    let lastScore = SKLabelNode(fontNamed: kFontName)
    lastScore.fontSize = kScoreFontSize
    lastScore.fontColor = SKColor(red: 255.0/255.0, green: 248.0/255.0, blue: 121.0/255.0, alpha: 1.0)
    lastScore.position = CGPoint(x: -scorecard.size.width * 0.17 * aspectRatio, y: -scorecard.size.height * 0.25 * aspectRatio)
    lastScore.zPosition = Layer.UI.rawValue
    lastScore.text = "\(score)"
    scorecard.addChild(lastScore)
    
    let lastScoreOutline = SKLabelNode(fontNamed: kFontName)
    lastScoreOutline.fontSize = kScoreFontSize
    lastScoreOutline.fontColor = SKColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    lastScoreOutline.position = CGPoint(x: -scorecard.size.width * 0.17 * aspectRatio + 5, y: -scorecard.size.height * 0.25 * aspectRatio - 6)
    lastScoreOutline.zPosition = Layer.UI.rawValue - 1
    lastScoreOutline.text = "\(score)"
    scorecard.addChild(lastScoreOutline)
    
    
    let bestScoreLabel = SKLabelNode(fontNamed: kFontName)
    bestScoreLabel.fontSize = kScoreFontSize
    bestScoreLabel.fontColor = SKColor(red: 255.0/255.0, green: 248.0/255.0, blue: 121.0/255.0, alpha: 1.0)
    bestScoreLabel.position = CGPoint(x: scorecard.size.width * 0.20 * aspectRatio, y: -scorecard.size.height * 0.25 * aspectRatio)
    bestScoreLabel.zPosition = Layer.UI.rawValue
    bestScoreLabel.text = "\(self.bestScore())"
    scorecard.addChild(bestScoreLabel)
    
    let bestScoreLabelOutline = SKLabelNode(fontNamed: kFontName)
    bestScoreLabelOutline.fontSize = kScoreFontSize
    bestScoreLabelOutline.fontColor = SKColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    bestScoreLabelOutline.position = CGPoint(x: scorecard.size.width * 0.20 * aspectRatio, y: -scorecard.size.height * 0.25 * aspectRatio)
    bestScoreLabelOutline.zPosition = Layer.UI.rawValue - 1
    bestScoreLabelOutline.text = "\(self.bestScore())"
    scorecard.addChild(bestScoreLabelOutline)
    
    
    let gameOver = SKSpriteNode(imageNamed: NSLocalizedString("GameOverImageName", comment: "Game Over Image Name"))
    gameOver.position = CGPoint(x: size.width/2, y: size.height/2 + scorecard.size.height/2 + 275 + gameOver.size.height/2)
    gameOver.xScale *= aspectRatio
    gameOver.yScale *= aspectRatio
    gameOver.zPosition = Layer.UI.rawValue
    worldNode.addChild(gameOver)
    
    let okButton = SKSpriteNode(imageNamed: "Button")
    okButton.xScale *= aspectRatio
    okButton.yScale *= aspectRatio
    okButton.position = CGPoint(x: size.width/2 - scorecard.size.width/2 + okButton.size.width/2,
      y: size.height/2 - scorecard.size.height/2 - kMargin - okButton.size.height/2)
    okButton.zPosition = Layer.UI.rawValue
    okButton.name = "okButton"
    worldNode.addChild(okButton)
    
    let ok = SKSpriteNode(imageNamed: NSLocalizedString("OKImageName", comment: "OK Image Name"))
    ok.position = CGPoint.zero
    ok.zPosition = Layer.UI.rawValue
    ok.name = "okLabel"
    okButton.addChild(ok)
    
    let shareButton = SKSpriteNode(imageNamed: "Button")
    shareButton.xScale *= aspectRatio
    shareButton.yScale *= aspectRatio
    shareButton.position = CGPoint(x: size.width/2 + scorecard.size.width/2 - shareButton.size.width/2,
      y: size.height/2 - scorecard.size.height/2 - kMargin - shareButton.size.height/2)
    shareButton.zPosition = Layer.UI.rawValue
    shareButton.name = "shareButton"
    worldNode.addChild(shareButton)
    
    let share = SKSpriteNode(imageNamed: NSLocalizedString("ShareImageName", comment: "Share Image Name"))
    share.position = CGPoint.zero
    share.zPosition = Layer.UI.rawValue
    share.name = "shareLabel"
    shareButton.addChild(share)
    
    
    // Game Center buttons Achievements & Leaderboards
    
    let achievementsButton = SKSpriteNode(imageNamed: "Button")
    achievementsButton.xScale *= aspectRatio
    achievementsButton.yScale *= aspectRatio
    achievementsButton.position = CGPoint(x: size.width/2 - scorecard.size.width/2 + okButton.size.width/2,
      y: size.height/2 - scorecard.size.height/2 - (kMargin * 11) - okButton.size.height/2)
    achievementsButton.zPosition = Layer.UI.rawValue
    achievementsButton.name = "achievementsButton"
    worldNode.addChild(achievementsButton)
    
    let achievements = SKSpriteNode(imageNamed: NSLocalizedString("AchievementsImageName",comment: "Achievements Image Name"))
    achievements.position = CGPoint.zero
    achievements.zPosition = Layer.UI.rawValue
    achievements.name = "achievements"
    achievementsButton.addChild(achievements)
    
    let leaderboardButton = SKSpriteNode(imageNamed: "Button")
    leaderboardButton.xScale *= aspectRatio
    leaderboardButton.yScale *= aspectRatio
    leaderboardButton.position = CGPoint(x: size.width/2 + scorecard.size.width/2 - shareButton.size.width/2,
      y: size.height/2 - scorecard.size.height/2 - (kMargin * 11) - shareButton.size.height/2)
    leaderboardButton.zPosition = Layer.UI.rawValue
    leaderboardButton.name = "leaderboardButton"
    worldNode.addChild(leaderboardButton)
    
    let leaderboard = SKSpriteNode(imageNamed: NSLocalizedString("LeaderboardImageName", comment: "Leaderboard Image Name"))
    leaderboard.position = CGPoint.zero
    leaderboard.zPosition = Layer.UI.rawValue
    leaderboard.name = "leaderboard"
    leaderboardButton.addChild(leaderboard)

    
    // Adding some ScoreCard Animations
    
    // Scale in GameOver Message
    gameOver.setScale(0)
    gameOver.alpha = 0
    let group = SKAction.group([
      SKAction.fadeInWithDuration(kAnimDelay),
      SKAction.scaleTo(aspectRatio, duration: kAnimDelay)
      ])
    group.timingMode = .EaseInEaseOut
    
    gameOver.runAction(SKAction.sequence([
      SKAction.waitForDuration(kAnimDelay),
      group
      ]))
    
    // Slide up ScoreCard
    scorecard.position = CGPoint(x:size.width * 0.5, y: -scorecard.size.height/2)
    let moveTo = SKAction.moveTo(CGPoint(x: size.width * 0.5, y: size.height * 0.60), duration: kAnimDelay)
    moveTo.timingMode = .EaseInEaseOut
    scorecard.runAction(SKAction.sequence([
      SKAction.waitForDuration(kAnimDelay * 2),
      moveTo
      ]))
    
    // Fade in Buttons
    okButton.alpha = 0
    shareButton.alpha = 0
    achievementsButton.alpha = 0
    leaderboardButton.alpha = 0
    
    let fadeIn = SKAction.sequence([
      SKAction.waitForDuration(kAnimDelay * 3),
      SKAction.fadeInWithDuration(kAnimDelay * 1.5)
      ])
    okButton.runAction(fadeIn)
    shareButton.runAction(fadeIn)
    achievementsButton.runAction(fadeIn)
    leaderboardButton.runAction(fadeIn)
    
    // Play animation sounds
    let pops = SKAction.sequence([
      SKAction.waitForDuration(kAnimDelay),
      popAction,
      SKAction.waitForDuration(kAnimDelay),
      popAction,
      SKAction.waitForDuration(kAnimDelay),
      popAction,
      SKAction.runBlock(switchToGameOver)
      ])
    runAction(pops)
    
  }
  
  func setupTutorial() {
    
    let ready = SKSpriteNode(imageNamed: NSLocalizedString("ReadyImageName", comment: "Ready Image Name"))
    ready.setScale(2.0)
    ready.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.75 + playableStart)
    ready.name = "Tutorial"
    ready.zPosition = Layer.UI.rawValue
    worldNode.addChild(ready)
    
    let tutorial = SKSpriteNode(imageNamed: NSLocalizedString("TutorialImageName", comment: "Tutorial Image Name"))
    tutorial.setScale(2.5)
    tutorial.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.4 + playableStart)
    tutorial.name = "Tutorial"
    tutorial.zPosition = Layer.UI.rawValue
    worldNode.addChild(tutorial)
    
    // Animate Ready & Tutorial
    ready.position = CGPoint(x: size.width * 0.5, y: size.height + ready.size.height/2)
    let moveTo = SKAction.moveTo(CGPoint(x: size.width * 0.5, y: playableHeight * 0.75 + playableStart), duration: 1.0)
    moveTo.timingMode = .EaseInEaseOut
    ready.runAction(SKAction.sequence([
      SKAction.waitForDuration(kAnimDelay),
      moveTo
      ]))
    
    let tutorialMoveUp = SKAction.moveByX(0, y: 50, duration: kAnimDelay)
    let tutorialMoveDown = SKAction.moveByX(0, y: -50, duration: kAnimDelay)
    let tutorialMoveUpDown = SKAction.sequence([
      tutorialMoveUp,
      tutorialMoveDown,
      SKAction.waitForDuration(0.1)])
    let bouceTutorial = SKAction.repeatActionForever(tutorialMoveUpDown)
    tutorial.runAction(bouceTutorial)
    
  }
  
  func setupMainMenu() {
    
    let logo = SKSpriteNode(imageNamed: NSLocalizedString("LogoImageName", comment: "Logo Image Name"))
    logo.setScale(2.0)
    logo.position = CGPoint(x: size.width/2, y: size.height * 0.8)
    logo.zPosition = Layer.UI.rawValue
    logo.name = "logo"
    worldNode.addChild(logo)
    
    // Play Button
    let playButton = SKSpriteNode(imageNamed: "Button")
    playButton.setScale(1.33)
    playButton.position = CGPoint(x: size.width * 0.20 + playButton.size.width/2, y: size.height * 0.30 - kMargin)
    playButton.zPosition = Layer.UI.rawValue
    playButton.name = "playButton"
    worldNode.addChild(playButton)
    
    let playLabel = SKSpriteNode(imageNamed: NSLocalizedString("PlayImageName", comment: "Play Image Name"))
    playLabel.position = CGPoint.zero
    playLabel.name = "playLabel"
    playButton.addChild(playLabel)
    
    // Rate Button
    let rateButton = SKSpriteNode(imageNamed: "RateButton")
    rateButton.setScale(1.33)
    rateButton.position = CGPoint(x: size.width * 0.80 - rateButton.size.width/2, y: size.height * 0.30 - kMargin)
    rateButton.zPosition = Layer.UI.rawValue
    rateButton.name = "rateButton"
    worldNode.addChild(rateButton)
    
    let rateLabel = SKSpriteNode(imageNamed: NSLocalizedString("RateImageName", comment: "Rate Image Name"))
    rateLabel.position = CGPoint.zero
    rateLabel.name = "rateLabel"
    rateButton.addChild(rateLabel)
    
    // Add our hero/player to screen
    player.setScale(1.75)
    player.position = CGPoint(x: size.width/2 - 10, y: size.height/2 + (kMargin * 7.0))
    
    // Animate hero/player
    let moveUp = SKAction.moveByX(0, y: 50, duration: 0.5)
    moveUp.timingMode = .EaseInEaseOut
    let moveDown = SKAction.moveByX(0, y: -50, duration: 0.5)
    moveDown.timingMode = .EaseInEaseOut
    
    player.runAction(SKAction.repeatActionForever(SKAction.sequence([
      moveUp, moveDown
      ])), withKey: "playerBounce")
    
  }
  
  
  func setupPlayerAnimation() {
    
    var textures: Array<SKTexture> = []
    for i in 0..<kNumPlayerFrames {
      textures.append(SKTexture(imageNamed: "Turtle_Universal_\(i)"))
    }
    for i in kNumPlayerFrames.stride(through: 0, by: -1) {
      textures.append(SKTexture(imageNamed: "Turtle_Universal_\(i)"))
    }
    
    let playerAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.07)
    player.runAction(SKAction.repeatActionForever(playerAnimation))
  }
  
  func setupTopObstacleAnimation() {
    
    var textures: Array<SKTexture> = []
    for i in 0..<kNumTopObstacleFrames {
      textures.append(SKTexture(imageNamed: "JellyFish_Universal_\(i)"))
    }
    for i in kNumTopObstacleFrames.stride(through: 0, by: -1) {
      textures.append(SKTexture(imageNamed: "JellyFish_Universal_\(i)"))
    }
    
    let topObstacleAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.07)
    topObstacle.runAction(SKAction.repeatActionForever(topObstacleAnimation))
  }
  
  // MARK: Gameplay
  
  func createObstacle(imageName: String) -> SKSpriteNode {
    let sprite = SKSpriteNode(imageNamed: imageName)
    sprite.zPosition = Layer.Obstacle.rawValue
    
    // Setup empty Dictionary for sprites userData
    sprite.userData = NSMutableDictionary()
    
    return sprite
  }
  
  func spawnObstacle() {
    
    let bottomObstacle = createObstacle("SeaPlants_Universal")
    let startX = size.width + bottomObstacle.size.width/2
    
    let bottomObstacleMin = (playableStart - bottomObstacle.size.height/2 + playableHeight * kBottomObstacleMinFraction)
    let bottomObstacleMax = (playableStart - bottomObstacle.size.height/2 + playableHeight * kBottomObstacleMaxFraction)
    bottomObstacle.xScale *= size.width / size.height * obstacleScaleFactor
    bottomObstacle.yScale *= size.width / size.height * obstacleScaleFactor
    bottomObstacle.position = CGPointMake(startX, CGFloat.random(min: bottomObstacleMin, max: bottomObstacleMax))
    
    
    let offsetX = bottomObstacle.size.width * bottomObstacle.anchorPoint.x
    let offsetY = bottomObstacle.size.height * bottomObstacle.anchorPoint.y
    
    let path = CGPathCreateMutable()
    
    CGPathMoveToPoint(path, nil, 112 - offsetX, 978 - offsetY)
    CGPathAddLineToPoint(path, nil, 86 - offsetX, 948 - offsetY)
    CGPathAddLineToPoint(path, nil, 55 - offsetX, 924 - offsetY)
    CGPathAddLineToPoint(path, nil, 53 - offsetX, 852 - offsetY)
    CGPathAddLineToPoint(path, nil, 45 - offsetX, 728 - offsetY)
    CGPathAddLineToPoint(path, nil, 59 - offsetX, 548 - offsetY)
    CGPathAddLineToPoint(path, nil, 1 - offsetX, 498 - offsetY)
    CGPathAddLineToPoint(path, nil, 4 - offsetX, 467 - offsetY)
    CGPathAddLineToPoint(path, nil, 37 - offsetX, 420 - offsetY)
    CGPathAddLineToPoint(path, nil, 28 - offsetX, 369 - offsetY)
    CGPathAddLineToPoint(path, nil, 43 - offsetX, 241 - offsetY)
    CGPathAddLineToPoint(path, nil, 45 - offsetX, 182 - offsetY)
    CGPathAddLineToPoint(path, nil, 49 - offsetX, 131 - offsetY)
    CGPathAddLineToPoint(path, nil, 26 - offsetX, 115 - offsetY)
    CGPathAddLineToPoint(path, nil, 31 - offsetX, 73 - offsetY)
    CGPathAddLineToPoint(path, nil, 5 - offsetX, 36 - offsetY)
    CGPathAddLineToPoint(path, nil, 42 - offsetX, 39 - offsetY)
    CGPathAddLineToPoint(path, nil, 58 - offsetX, 15 - offsetY)
    CGPathAddLineToPoint(path, nil, 93 - offsetX, 4 - offsetY)
    CGPathAddLineToPoint(path, nil, 166 - offsetX, 13 - offsetY)
    CGPathAddLineToPoint(path, nil, 148 - offsetX, 75 - offsetY)
    CGPathAddLineToPoint(path, nil, 131 - offsetX, 88 - offsetY)
    CGPathAddLineToPoint(path, nil, 162 - offsetX, 136 - offsetY)
    CGPathAddLineToPoint(path, nil, 162 - offsetX, 330 - offsetY)
    CGPathAddLineToPoint(path, nil, 161 - offsetX, 392 - offsetY)
    CGPathAddLineToPoint(path, nil, 131 - offsetX, 402 - offsetY)
    CGPathAddLineToPoint(path, nil, 149 - offsetX, 466 - offsetY)
    CGPathAddLineToPoint(path, nil, 148 - offsetX, 514 - offsetY)
    CGPathAddLineToPoint(path, nil, 162 - offsetX, 651 - offsetY)
    CGPathAddLineToPoint(path, nil, 173 - offsetX, 673 - offsetY)
    CGPathAddLineToPoint(path, nil, 202 - offsetX, 665 - offsetY)
    CGPathAddLineToPoint(path, nil, 207 - offsetX, 695 - offsetY)
    CGPathAddLineToPoint(path, nil, 163 - offsetX, 705 - offsetY)
    CGPathAddLineToPoint(path, nil, 165 - offsetX, 959 - offsetY)
    CGPathAddLineToPoint(path, nil, 153 - offsetX, 995 - offsetY)
    CGPathAddLineToPoint(path, nil, 141 - offsetX, 952 - offsetY)
    CGPathAddLineToPoint(path, nil, 124 - offsetX, 951 - offsetY)
    CGPathAddLineToPoint(path, nil, 126 - offsetX, 965 - offsetY)
    
    CGPathCloseSubpath(path)
    
    bottomObstacle.physicsBody = SKPhysicsBody(polygonFromPath: path)
    bottomObstacle.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
    bottomObstacle.physicsBody?.collisionBitMask = 0
    bottomObstacle.physicsBody?.contactTestBitMask = PhysicsCategory.Player
    
    bottomObstacle.name = "bottomObstacle"
    
    worldNode.addChild(bottomObstacle)
    
    let topObstacle = createObstacle("JellyFish_Universal_0")
    topObstacle.position = CGPoint(x: startX, y: bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + player.size.height * kGapMultiplier)
    topObstacle.xScale *= size.width / size.height * obstacleScaleFactor
    topObstacle.yScale *= size.width / size.height * obstacleScaleFactor
    
    let offsetX_2 = topObstacle.size.width * topObstacle.anchorPoint.x
    let offsetY_2 = topObstacle.size.height * topObstacle.anchorPoint.y
    
    let path_2 = CGPathCreateMutable()
    
    CGPathMoveToPoint(path_2, nil, 69 - offsetX_2, 713 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 30 - offsetX_2, 691 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 8 - offsetX_2, 649 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 16 - offsetX_2, 619 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 38 - offsetX_2, 609 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 40 - offsetX_2, 561 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 34 - offsetX_2, 512 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 35 - offsetX_2, 470 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 37 - offsetX_2, 419 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 41 - offsetX_2, 387 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 60 - offsetX_2, 363 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 27 - offsetX_2, 342 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 9 - offsetX_2, 316 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 7 - offsetX_2, 278 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 34 - offsetX_2, 264 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 24 - offsetX_2, 208 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 18 - offsetX_2, 153 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 19 - offsetX_2, 116 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 18 - offsetX_2, 66 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 26 - offsetX_2, 34 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 41 - offsetX_2, 37 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 59 - offsetX_2, 10 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 72 - offsetX_2, 47 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 90 - offsetX_2, 47 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 94 - offsetX_2, 15 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 113 - offsetX_2, 34 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 120 - offsetX_2, 53 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 131 - offsetX_2, 50 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 136 - offsetX_2, 59 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 117 - offsetX_2, 148 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 131 - offsetX_2, 194 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 163 - offsetX_2, 167 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 185 - offsetX_2, 197 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 207 - offsetX_2, 171 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 230 - offsetX_2, 199 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 247 - offsetX_2, 220 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 236 - offsetX_2, 277 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 226 - offsetX_2, 303 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 231 - offsetX_2, 341 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 237 - offsetX_2, 381 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 225 - offsetX_2, 424 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 246 - offsetX_2, 439 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 224 - offsetX_2, 496 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 173 - offsetX_2, 520 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 142 - offsetX_2, 528 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 131 - offsetX_2, 608 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 152 - offsetX_2, 617 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 149 - offsetX_2, 660 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 129 - offsetX_2, 693 - offsetY_2)
    CGPathAddLineToPoint(path_2, nil, 99 - offsetX_2, 710 - offsetY_2)
    
    CGPathCloseSubpath(path_2)
    
    topObstacle.physicsBody = SKPhysicsBody(polygonFromPath: path_2)
    topObstacle.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
    topObstacle.physicsBody?.collisionBitMask = 0
    topObstacle.physicsBody?.contactTestBitMask = PhysicsCategory.Player
    
    topObstacle.name = "topObstacle"
    
    worldNode.addChild(topObstacle)
    
    let moveX = size.width + bottomObstacle.size.width
    let moveDuration = moveX / kGroundSpeed
    let sequence = SKAction.sequence([
      SKAction.moveByX(-moveX, y: 0, duration: NSTimeInterval(moveDuration)),
      SKAction.removeFromParent()
      ])
    topObstacle.runAction(sequence)
    bottomObstacle.runAction(sequence)
    
  }
  
  func startSpawning() {
    
    let firstDelay = SKAction.waitForDuration(kFirstSpawnDelay)
    let spawn = SKAction.runBlock(spawnObstacle)
    let everyDelay = SKAction.waitForDuration(kEverySpawnDelay)
    let spawnSequence = SKAction.sequence([
      spawn, everyDelay
      ])
    let foreverSpawn = SKAction.repeatActionForever(spawnSequence)
    let overallSequence = SKAction.sequence([firstDelay, foreverSpawn])
    runAction(overallSequence, withKey: "spawn")
    
  }
  
  func stopSpawning() {
    
    // Stop the spawn creation of obstacles
    removeActionForKey("spawn")
    
    // Stop the moving actions of ones already created
    worldNode.enumerateChildNodesWithName("topObstacle", usingBlock: { node, stop in
      node.removeAllActions()
    })
    
    worldNode.enumerateChildNodesWithName("bottomObstacle", usingBlock: { node, stop in
      node.removeAllActions()
    })
    
  }
  
  func flapPlayer() {
    
    // Play sound
    runAction(flapAction)
    
    playerVelocity = CGPoint(x: 0, y: kImpluse)
    playerAngularVelocity = kAngularVelocity.degreesToRadians()
    lastTouchTime = lastUpdateTime
    lastTouchY = player.position.y
    
    // Move Hat
    let moveUp = SKAction.moveByX(0, y: 20, duration: 0.15)
    moveUp.timingMode = .EaseInEaseOut
    let moveDown = moveUp.reversedAction()
    playerHat.runAction(SKAction.sequence([ moveUp, moveDown]))
    
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    
    //    if let touch = touches.first {
    //      print("\(touch)")
    //    }
    
    for touch: AnyObject! in touches {
      let touchLocation = touch.locationInNode(self)
      let touchedNode = self.nodeAtPoint(touchLocation)
      
      switch gameState {
      case .MainMenu:
        if touchedNode.name == "playButton" || touchedNode.name == "playLabel" {
          switchToNewGame(.Tutorial)
        }
        if touchedNode.name == "rateButton" || touchedNode.name == "rateLabel" {
          rateApp()
        }
        break
      case .Tutorial:
        switchToPlay()
        break
      case .Play:
        flapPlayer()
        break
      case .Falling:
        break
      case .ShowingScore:
        break
      case .GameOver:
        if touchedNode.name == "okButton" || touchedNode.name == "okLabel" {
          switchToNewGame(.MainMenu)
        }
        if touchedNode.name == "shareButton" || touchedNode.name == "shareLabel" {
          shareScore()
        }
        if touchedNode.name == "achievementsButton" || touchedNode.name == "achievements" {
          showGameCenter("Achievements")
        }
        if touchedNode.name == "leaderboardButton" || touchedNode.name == "leaderboard" {
          showGameCenter("Leaderboards")
        }
        break
      }
    }
  }
  
  
  // MARK: Updates
  
  override func update(currentTime: CFTimeInterval) {
    
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime
    
    switch gameState {
    case .MainMenu:
      break
    case .Tutorial:
      break
    case .Play:
      updateForeground()
      updateBackground()
      updatePlayer()
      checkHitObstacle()
      checkHitGround()
      updateScore()
      break
    case .Falling:
      updatePlayer()
      checkHitGround()
      break
    case .ShowingScore:
      break
    case .GameOver:
      break
    }
    
  }
  
  func updatePlayer() {
    
    // Apply gravity
    let gravity = CGPoint(x: 0, y: Gravity)
    let gravityStep = gravity * CGFloat(dt)
    playerVelocity += gravityStep
    
    // Apply velocity
    let velocityStep = playerVelocity * CGFloat(dt)
    player.position += velocityStep
    player.position = CGPoint(x: player.position.x, y: min(player.position.y, size.height))
    
    if player.position.y < lastTouchY {
      playerAngularVelocity = -kAngularVelocity.degreesToRadians()
    }
    
    // Rotate Player
    let angularStep = playerAngularVelocity * CGFloat(dt)
    player.zRotation += angularStep
    player.zRotation = min(max(player.zRotation, kMinDegrees.degreesToRadians()), kMaxDegrees.degreesToRadians())
    
  }
  
  func updateForeground() {
    
    if gameState == .Play {
      
      worldNode.enumerateChildNodesWithName("foreground", usingBlock: { node, stop in
        if let foreground = node as? SKSpriteNode {
          let moveAmt = CGPoint(x: -self.kGroundSpeed * CGFloat(self.dt), y: 0)
          foreground.position += moveAmt
          
          if foreground.position.x < -foreground.size.width {
            foreground.position += CGPoint(x: foreground.size.width * CGFloat(self.kNumForegrounds), y: 0)
          }
        }
      })
    }
  }
  
  func updateBackground() {
    
    if gameState == .Play {
      
      worldNode.enumerateChildNodesWithName("background", usingBlock: { node, stop in
        if let background = node as? SKSpriteNode {
          let moveAmt = CGPoint(x: -self.kBackgroundSpeed * CGFloat(self.dt), y: 0)
          background.position += moveAmt
          
          if background.position.x < -background.size.width {
            background.position += CGPoint(x: background.size.width * CGFloat(self.kNumBackgrounds), y: 0)
          }
        }
      })
    }
  }
  
  func checkHitObstacle() {
    
    if hitObstacle {
      hitObstacle = false
      switchToFalling()
    }
  }
  
  func checkHitGround() {
    
    if hitGround {
      hitGround = false
      playerVelocity = CGPoint.zero
      player.zRotation = CGFloat(-85).degreesToRadians()
      player.position = CGPoint(x: player.position.x, y: playableStart + player.size.width * 0.4)
      runAction(hitGroundAction)
      switchToShowScore()
    }
    
  }
  
  func updateScore() {
    
    worldNode.enumerateChildNodesWithName("bottomObstacle", usingBlock: { node, stop in
      if let obstacle = node as? SKSpriteNode {
        if let passed = obstacle.userData?["Passed"] as? NSNumber {
          if passed.boolValue {
            return
          }
        }
        if self.player.position.x > obstacle.position.x + obstacle.size.width/2 {
          self.score++
          self.scoreLabel.text = "\(self.score)"
          self.scoreLabelBackground.text = "\(self.score)"
          self.runAction(self.coinAction)
          obstacle.userData?["Passed"] = NSNumber(bool: true)
          self.checkIfAchievementEarned()
        }
      }
    })
    
  }
  
  // MARK: Game States
  
  func switchToFalling() {
    
    gameState = .Falling
    
    // Screen shake
    let shake = SKAction.screenShakeWithNode(worldNode, amount: CGPoint(x: 0, y: 17.0), oscillations: 10, duration: 1.0)
    worldNode.runAction(shake)
    
    // Flash Screen
    let whiteNode = SKSpriteNode(color: SKColor.whiteColor(), size: size)
    whiteNode.position = CGPoint(x: size.width/2, y: size.height/2)
    whiteNode.zPosition = Layer.Flash.rawValue
    worldNode.addChild(whiteNode)
    
    whiteNode.runAction(SKAction.removeFromParentAfterDelay(0.01))
    
    runAction(SKAction.sequence([
      whackAction,
      SKAction.waitForDuration(0.1),
      fallingAction
      ]))
    
    player.removeAllActions()
    stopSpawning()
    
  }
  
  func switchToShowScore() {
    
    gameState = .ShowingScore
    player.removeAllActions()
    stopSpawning()
    setupScorecard()
    
  }
  
  func switchToNewGame(gameState: GameState) {
    
    runAction(popAction)
    
    let newScene = GameScene(size: CGSize(width: 1536, height: 2048),delegate: gameSceneDelegate, gameState: gameState)
    newScene.scaleMode = .AspectFill
    let transition = SKTransition.fadeWithColor(SKColor.blackColor(), duration: 0.5)
    view?.presentScene(newScene, transition: transition)
    
  }
  
  func switchToGameOver() {
    
    gameState = .GameOver
    
  }
  
  func switchToMainMenu() {
    
    gameState = .MainMenu
    
    setupBackground()
    setupForeground()
    setupPlayer()
  //  setupPlayerHat()
    setupMainMenu()
    setupPlayerAnimation()
    
  }
  
  func switchToTutorial() {
    
    gameState = .Tutorial
    
    setupBackground()
    setupForeground()
    //setupPlayer()
    //setupPlayerHat()
    setupLabel()
    setupTutorial()
    setupPlayerAnimation()
    
  }
  
  func switchToPlay() {
    
    // Set state
    gameState = .Play
    
    // Remove Tutorial
    worldNode.enumerateChildNodesWithName("Tutorial", usingBlock: { node, stop in
      node.runAction(SKAction.sequence([
        SKAction.fadeOutWithDuration(0.3),
        SKAction.removeFromParent()
        ]))
    })
    
    // Stop player bounce
    player.removeActionForKey("playerBounce")
    
    // Add Player to scene
    setupPlayer()
    
    // Start spawning
    startSpawning()
    
    
    // Move Player
    flapPlayer()
    
  }
  
  
  // MARK: Score Card
  
  func bestScore() -> Int {
    return NSUserDefaults.standardUserDefaults().integerForKey("BestScore")
  }
  
  func setBestScore(bestScore: Int) {
    NSUserDefaults.standardUserDefaults().setInteger(bestScore, forKey: "BestScore")
    NSUserDefaults.standardUserDefaults().synchronize()
  }
  
  func shareScore() {
    
    let urlString = "http://itunes.apple.com/app/id\(kAppStoreID)?mt=8"
    let url = NSURL(string: urlString)
    
    // Use delegate to get a screen shot
    let screenShot = gameSceneDelegate.screenShot()
    // Text we want to share
    let string1 = NSLocalizedString("ShareText_1", comment: "Share text localized 1st part")
    let string2 = " \(score) " + NSLocalizedString("ShareText_2", comment: "Share text localized 2nd part")
    let initialTextString = string1 + string2
    gameSceneDelegate.shareString(initialTextString, url: url!, image: screenShot)
    
  }
  
  func rateApp() {
    
    let urlString = "http://itunes.apple.com/app/id\(kAppStoreID)?mt=8"
    let url = NSURL(string: urlString)
    UIApplication.sharedApplication().openURL(url!)
    
  }
  
  
  // MARK: Physics
  
  func didBeginContact(contact: SKPhysicsContact) {
    let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
    
    if other.categoryBitMask == PhysicsCategory.Ground {
      hitGround = true
    }
    if other.categoryBitMask == PhysicsCategory.Obstacle {
      hitObstacle = true
    }
  }
  
  
  // MARK: Game Center
  
  func authenticateLocalPlayer() {
    
    let localPlayer = GKLocalPlayer.localPlayer()
    
    localPlayer.authenticateHandler = { (viewController, error ) -> Void in
      
      if (viewController != nil) {
        // If not authenticated, popup view controller to log into Game Center
        let vc:UIViewController = self.view!.window!.rootViewController!
        vc.presentViewController(viewController!, animated: true, completion: nil)
      } else {
        print("Authentication is \(GKLocalPlayer.localPlayer().authenticated) ")
        // do something based on the player being logged in.
        
        self.gameCenterAchievements.removeAll()
        self.loadAchievementPercentages()
        
      }
    }
    
  }
  
  func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
    
    gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    
    gameCenterAchievements.removeAll()
    loadAchievementPercentages()
    
  }
  
  func showGameCenter(viewState: String = "") {
    
    let gameCenterViewController = GKGameCenterViewController()
    
    gameCenterViewController.gameCenterDelegate = self

    // options for what to initially show...
    if viewState == "Achievements" {
      gameCenterViewController.viewState = GKGameCenterViewControllerState.Achievements
    } else if viewState == "Leaderboards" {
      gameCenterViewController.leaderboardIdentifier = kLeaderboardID
      gameCenterViewController.viewState = GKGameCenterViewControllerState.Leaderboards
    }
    
    let vc:UIViewController = self.view!.window!.rootViewController!
    vc.presentViewController(gameCenterViewController, animated: true, completion: nil)
    
  }
  
  func saveHighScore(identifier: String, score: Int) {
    
    if (GKLocalPlayer.localPlayer().authenticated) {
      
      let scoreReporter = GKScore(leaderboardIdentifier: identifier)
      
      scoreReporter.value = Int64(score)
      
      scoreReporter.shouldSetDefaultLeaderboard = true
      
      let scoreArray:[GKScore] = [scoreReporter]
      
      GKScore.reportScores(scoreArray, withCompletionHandler: {
        
        error -> Void in
        
        if (error != nil) {
          print("\(error)")
        } else {
          
          print("Posted score of \(score)")
          // From here you can do anything else to tell the user they posted a high score
        }
      })
      
    }
  }
  
  func loadAchievementPercentages() {
    
    print("getting percentage of past achievements")
    GKAchievement.loadAchievementsWithCompletionHandler({ (allAchievements, error) -> Void in
      
      if error != nil {
        print("Game center could not load achievements, the error is \(error)")
      } else {
        // this could be nil if there was no progress on any achievements thus far
        if (allAchievements != nil) {
          
          for theAchievement in allAchievements! {
            
            if let singleAchievement:GKAchievement = theAchievement {
              self.gameCenterAchievements[singleAchievement.identifier!] = singleAchievement
            }
          }
          
          for (id, achievement) in self.gameCenterAchievements {
            print("\(id) - \(achievement.percentComplete)")
          }
        }
      }
    })
    
  }
  
  func incrementCurrentPercentOfAchievement(identifier: String, amount: Double) {
    
    if GKLocalPlayer.localPlayer().authenticated {
      
      var currentPercentFound:Bool = false
      
      if (gameCenterAchievements.count != 0) {
        
        for (id, achievement) in gameCenterAchievements {
          
          if (id == identifier) {
            
            currentPercentFound = true
            
            var currentPercent:Double = achievement.percentComplete
            currentPercent = currentPercent + amount
            
            reportAchievement(identifier, percentComplete:currentPercent)
            break
          }
        }
      }
      
      if (currentPercentFound == false) {
        
        reportAchievement(identifier, percentComplete: amount)
        
      }
      
    }
  }
  
  func reportAchievement(identifier: String, percentComplete: Double) {
    
    let achievement = GKAchievement(identifier: identifier)
    
    achievement.percentComplete = percentComplete
   
    achievement.showsCompletionBanner = true
    
    let achievementArray:[GKAchievement] = [achievement]
    
    GKAchievement.reportAchievements(achievementArray, withCompletionHandler: {
      
      error -> Void in
      
      if ( error != nil) {
        print("\(error)")
      } else {
        
        print("reported achievement with percent complete of \(percentComplete)")
        
        self.gameCenterAchievements.removeAll()
        self.loadAchievementPercentages()
      }
      
    })
    
  }
  
  func clearAchievementsInGameCenter() {
    
    GKAchievement.resetAchievementsWithCompletionHandler({
      (error) -> Void in
      
      if (error != nil ) {
        print("\(error)")
      } else {
        
        print("clearing all achievements in Game Center")
        self.gameCenterAchievements.removeAll()
      
      }
    })
    
  }
  
  func checkIfAchievementEarned() {
    
    if (self.score > 0 && self.score <= kHappyHatchlingAchievementPoints) {
      achievementPercent = Double(CGFloat(self.score) / CGFloat(kHappyHatchlingAchievementPoints) * 100)
      reportAchievement(kHappyHatchlingAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kHappyHatchlingAchievementPoints && self.score <= kFlappingFlippersAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kHappyHatchlingAchievementPoints)) / CGFloat(kFlappingFlippersAchievementPoints - kHappyHatchlingAchievementPoints) * 100)
      reportAchievement(kFlappingFlippersAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kFlappingFlippersAchievementPoints && self.score <= kClappingClamsAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kFlappingFlippersAchievementPoints)) / CGFloat(kClappingClamsAchievementPoints - kFlappingFlippersAchievementPoints) * 100)
      reportAchievement(kClappingClamsAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kClappingClamsAchievementPoints && self.score <= kBubbleBusterAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kClappingClamsAchievementPoints)) / CGFloat(kBubbleBusterAchievementPoints - kClappingClamsAchievementPoints) * 100)
      reportAchievement(kBubbleBusterAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kBubbleBusterAchievementPoints && self.score <= kStarfishSurpriseAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kBubbleBusterAchievementPoints)) / CGFloat(kStarfishSurpriseAchievementPoints - kBubbleBusterAchievementPoints) * 100)
      reportAchievement(kStarfishSurpriseAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kStarfishSurpriseAchievementPoints && self.score <= kJellyfishSandwichAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kStarfishSurpriseAchievementPoints)) / CGFloat(kJellyfishSandwichAchievementPoints - kStarfishSurpriseAchievementPoints) * 100)
      reportAchievement(kJellyfishSandwichAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kJellyfishSandwichAchievementPoints && self.score <= kEACRiderAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kJellyfishSandwichAchievementPoints)) / CGFloat(kEACRiderAchievementPoints - kJellyfishSandwichAchievementPoints) * 100)
      reportAchievement(kEACRiderAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kEACRiderAchievementPoints && self.score <= kSuperSheldonAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kEACRiderAchievementPoints)) / CGFloat(kSuperSheldonAchievementPoints - kEACRiderAchievementPoints) * 100)
      reportAchievement(kSuperSheldonAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kSuperSheldonAchievementPoints && self.score <= kRayRunnerAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kSuperSheldonAchievementPoints)) / CGFloat(kRayRunnerAchievementPoints - kSuperSheldonAchievementPoints) * 100)
      reportAchievement(kRayRunnerAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kRayRunnerAchievementPoints && self.score <= kDancingDaphneAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kRayRunnerAchievementPoints)) / CGFloat(kDancingDaphneAchievementPoints - kRayRunnerAchievementPoints) * 100)
      reportAchievement(kDancingDaphneAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kDancingDaphneAchievementPoints && self.score <= kInkingOllieAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kDancingDaphneAchievementPoints)) / CGFloat(kInkingOllieAchievementPoints - kDancingDaphneAchievementPoints) * 100)
      reportAchievement(kInkingOllieAchievementId, percentComplete: achievementPercent)
    }
    if (self.score > kInkingOllieAchievementPoints && self.score <= kSharkAlleyAchievementPoints) {
      achievementPercent = Double((CGFloat(self.score) - CGFloat(kInkingOllieAchievementPoints)) / CGFloat(kSharkAlleyAchievementPoints - kInkingOllieAchievementPoints) * 100)
      reportAchievement(kSharkAlleyAchievementId, percentComplete: achievementPercent)
    }
    
  }
  
  // MARK: Date Calculations
  
  func howManyDaysUntil(end: String, start: NSDate = NSDate()) -> Int {
    
    //    let start = "01-01-2016"
    //    let end = "12-25-2016"
    
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "MM-dd-yyyy"
    
    // let startDate:NSDate = dateFormatter.dateFromString(start)!
    let endDate:NSDate = dateFormatter.dateFromString(end)!
    
    let numOfDays = daysBetweenDate(start, endDate: endDate)
    
    print("Number of days: \(numOfDays)")
    return numOfDays
  }
  
  func daysBetweenDate(startDate: NSDate, endDate: NSDate) -> Int {
    let calendar = NSCalendar.currentCalendar()
    
    let components = calendar.components([.Day], fromDate: startDate, toDate: endDate, options: [])
    
    return components.day
  }
  
}
