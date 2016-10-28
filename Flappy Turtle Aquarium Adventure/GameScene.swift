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
  case background
  case obstacle
  case foreground
  case player
  case ui
  case flash
}

enum GameState {
  case mainMenu
  case tutorial
  case play
  case falling
  case showingScore
  case gameOver
}

struct PhysicsCategory {
  static let None: UInt32 = 0
  static let Player: UInt32 =      0b1   // 1
  static let Obstacle: UInt32 =   0b10   // 2
  static let Ground: UInt32 =    0b100   // 4
}

protocol GameSceneDelegate {
  
  func screenShot() -> UIImage
  func shareString(_ string: String, url: URL, image: UIImage)
}


class GameScene: SKScene, SKPhysicsContactDelegate, ADBannerViewDelegate, GKGameCenterControllerDelegate {
  
  // MARK: Constants
  
  var Gravity: CGFloat = -1500.0
  var kImpluse: CGFloat =  600.0
  let kNumBackgrounds = 4
  let kNumForegrounds = 2
  let kNumTopObstacles = 24
  let kNumBottomObstacles = 0  // not used in this version
  var kGroundSpeed: CGFloat = 300.0 // 150.0
  var kBackgroundSpeed: CGFloat = 50.0
  let kBottomObstacleMinFraction: CGFloat = 0.05 // 5%
  let kBottomObstacleMaxFraction: CGFloat = 0.585 // 58.5%
  var kGapMultiplier: CGFloat = 1.50
  let kFirstSpawnDelay: TimeInterval = 1.75
  var kEverySpawnDelay: TimeInterval = 2.5  // 4.75
  let kFontName = "AmericanTypewriter-Bold"
  let kScoreFontSize: CGFloat = 110
  let kMargin: CGFloat = 24.0
  let kAnimDelay = 0.3
  let kNumPlayerFrames = 12
  let kNumTopObstacleFrames = 24
  let kMinDegrees: CGFloat = -90
  let kMaxDegrees: CGFloat =  12
  var kAngularVelocity: CGFloat = 200.0
  
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
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  var playerVelocity = CGPoint.zero
  //  let playerHat = SKSpriteNode(imageNamed: "hat-christmas")
  let playerHat = SKSpriteNode(imageNamed: "")
  var hitGround: Bool = false
  var hitObstacle: Bool = false
  var gameState: GameState = .tutorial
  var scoreLabel: SKLabelNode!
  var scoreLabelBackground: SKLabelNode!
  var score = 0
  var gameSceneDelegate: GameSceneDelegate
  var playerAngularVelocity: CGFloat = 0.0
  var lastTouchTime: TimeInterval = 0
  var lastTouchY: CGFloat = 0.0
  var gameCenterAchievements = [String: GKAchievement]()  // Achievements Dictionary
  var achievementPercent:Double = 0

  var isMusicOn: Bool = true
  var musicButtonOn = SKSpriteNode(imageNamed: "music_on")
  var musicButtonOff = SKSpriteNode(imageNamed: "music_off")
  
  
  // MARK: Sounds
  
  let dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
  let flapAction = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
  let whackAction = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
  let fallingAction = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
  let hitGroundAction = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
  let popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
  let coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
  
  func toggleMusic() {
    if isMusicOn == true {
      // Turn it off
      fadePlayer(backgroundMusicPlayer, fromVolume: 0.4, toVolume: 0.0, overTime: 1.0)
      musicButtonOn.isHidden = true
      musicButtonOff.isHidden = false
      isMusicOn = false
      setMusicSetting(false)
    } else if isMusicOn == false {
      // Turn it on
      playBackgroundMusic("Dancing on Green Grass.mp3")
      fadePlayer(backgroundMusicPlayer, fromVolume: 0.0, toVolume: 0.4, overTime: 2.0)
      musicButtonOn.isHidden = false
      musicButtonOff.isHidden = true
      isMusicOn = true
      setMusicSetting(true)
    }
    
  }
  
  func getMusicSetting() -> Bool {
    let musicSetting = UserDefaults.standard.bool(forKey: "MusicSetting")
    if musicSetting == true {
      isMusicOn = true
    } else {
      isMusicOn = false
    }
    
    // print("Music settings were read to be: ", musicSetting)
    return musicSetting
  }
  
  func setMusicSetting(_ isOn: Bool) {
    UserDefaults.standard.set(isOn, forKey: "MusicSetting")
    UserDefaults.standard.synchronize()
  }
  
  // Override init to
  init(size: CGSize, delegate:GameSceneDelegate, gameState: GameState) {
    
    self.gameSceneDelegate = delegate
    
    // Set Initial GameState
    self.gameState = gameState
    
    super.init(size: size)
    
    isMusicOn = getMusicSetting()
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  // MARK: didMoveToView
  
  override func didMove(to view: SKView) {
    
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
    
    if gameState == .mainMenu {
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
      background.zPosition = Layer.background.rawValue
      background.name = "background"
      
      let lowerLeft = CGPoint(x: 0, y: playableStart)
      let lowerRight = CGPoint(x: size.width, y: playableStart)
      
      self.physicsBody = SKPhysicsBody(edgeFrom: lowerLeft, to: lowerRight)
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
      foreground.zPosition = Layer.foreground.rawValue
      foreground.name = "foreground"
      worldNode.addChild(foreground)
    }
  }
  
  func setupPlayer() {
    
    aspectRatio = size.height / size.width
    //  print("AspectRatio = \(aspectRatio)")
    
    player.position = CGPoint(x: (size.width * 0.20) * aspectRatio, y: playableHeight * 0.4 + playableStart)
    player.zPosition = Layer.player.rawValue
    let offsetX = player.size.width * player.anchorPoint.x
    let offsetY = player.size.height * player.anchorPoint.y
    
    let path = CGMutablePath()
    
    path.move(to: CGPoint(x: 100 - offsetX, y: 143 - offsetY))
    path.addLine(to: CGPoint(x: 71 - offsetX, y: 136 - offsetY))
    path.addLine(to: CGPoint(x: 50 - offsetX, y: 105 - offsetY))
    path.addLine(to: CGPoint(x: 38 - offsetX, y: 88 - offsetY))
    path.addLine(to: CGPoint(x: 16 - offsetX, y: 96 - offsetY))
    path.addLine(to: CGPoint(x: 37 - offsetX, y: 80 - offsetY))
    path.addLine(to: CGPoint(x: 48 - offsetX, y: 79 - offsetY))
    path.addLine(to: CGPoint(x: 53 - offsetX, y: 72 - offsetY))
    path.addLine(to: CGPoint(x: 14 - offsetX, y: 77 - offsetY))
    path.addLine(to: CGPoint(x: 13 - offsetX, y: 61 - offsetY))
    path.addLine(to: CGPoint(x: 39 - offsetX, y: 40 - offsetY))
    path.addLine(to: CGPoint(x: 72 - offsetX, y: 47 - offsetY))
    path.addLine(to: CGPoint(x: 86 - offsetX, y: 60 - offsetY))
    path.addLine(to: CGPoint(x: 129 - offsetX, y: 65 - offsetY))
    path.addLine(to: CGPoint(x: 127 - offsetX, y: 60 - offsetY))
    path.addLine(to: CGPoint(x: 99 - offsetX, y: 36 - offsetY))
    path.addLine(to: CGPoint(x: 96 - offsetX, y: 19 - offsetY))
    path.addLine(to: CGPoint(x: 109 - offsetX, y: 16 - offsetY))
    path.addLine(to: CGPoint(x: 130 - offsetX, y: 22 - offsetY))
    path.addLine(to: CGPoint(x: 146 - offsetX, y: 32 - offsetY))
    path.addLine(to: CGPoint(x: 150 - offsetX, y: 23 - offsetY))
    path.addLine(to: CGPoint(x: 163 - offsetX, y: 29 - offsetY))
    path.addLine(to: CGPoint(x: 173 - offsetX, y: 56 - offsetY))
    path.addLine(to: CGPoint(x: 162 - offsetX, y: 96 - offsetY))
    path.addLine(to: CGPoint(x: 185 - offsetX, y: 111 - offsetY))
    path.addLine(to: CGPoint(x: 215 - offsetX, y: 95 - offsetY))
    path.addLine(to: CGPoint(x: 247 - offsetX, y: 100 - offsetY))
    path.addLine(to: CGPoint(x: 241 - offsetX, y: 113 - offsetY))
    path.addLine(to: CGPoint(x: 262 - offsetX, y: 118 - offsetY))
    path.addLine(to: CGPoint(x: 256 - offsetX, y: 152 - offsetY))
    path.addLine(to: CGPoint(x: 232 - offsetX, y: 172 - offsetY))
    path.addLine(to: CGPoint(x: 203 - offsetX, y: 176 - offsetY))
    path.addLine(to: CGPoint(x: 171 - offsetX, y: 167 - offsetY))
    path.addLine(to: CGPoint(x: 164 - offsetX, y: 144 - offsetY))
    path.addLine(to: CGPoint(x: 168 - offsetX, y: 122 - offsetY))
    path.addLine(to: CGPoint(x: 160 - offsetX, y: 112 - offsetY))
    path.addLine(to: CGPoint(x: 131 - offsetX, y: 138 - offsetY))
    
    path.closeSubpath()
    
    player.physicsBody = SKPhysicsBody(polygonFrom: path)
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
    scoreLabel.verticalAlignmentMode = .top
    scoreLabel.zPosition = Layer.ui.rawValue
    scoreLabel.fontSize = kScoreFontSize
    worldNode.addChild(scoreLabel)
    
    scoreLabelBackground = SKLabelNode(fontNamed: kFontName)
    scoreLabelBackground.fontColor = SKColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    scoreLabelBackground.position = CGPoint(x: size.width/2 + 5, y: size.height - kMargin - 5)
    scoreLabelBackground.text = scoreLabel.text
    scoreLabelBackground.verticalAlignmentMode = .top
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
    scorecard.zPosition = Layer.ui.rawValue
    worldNode.addChild(scorecard)
    
    let lastScore = SKLabelNode(fontNamed: kFontName)
    lastScore.fontSize = kScoreFontSize
    lastScore.fontColor = SKColor(red: 255.0/255.0, green: 248.0/255.0, blue: 121.0/255.0, alpha: 1.0)
    lastScore.position = CGPoint(x: -scorecard.size.width * 0.17 * aspectRatio, y: -scorecard.size.height * 0.25 * aspectRatio)
    lastScore.zPosition = Layer.ui.rawValue
    lastScore.text = "\(score)"
    scorecard.addChild(lastScore)
    
    let lastScoreOutline = SKLabelNode(fontNamed: kFontName)
    lastScoreOutline.fontSize = kScoreFontSize
    lastScoreOutline.fontColor = SKColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    lastScoreOutline.position = CGPoint(x: -scorecard.size.width * 0.17 * aspectRatio + 5, y: -scorecard.size.height * 0.25 * aspectRatio - 6)
    lastScoreOutline.zPosition = Layer.ui.rawValue - 1
    lastScoreOutline.text = "\(score)"
    scorecard.addChild(lastScoreOutline)
    
    
    let bestScoreLabel = SKLabelNode(fontNamed: kFontName)
    bestScoreLabel.fontSize = kScoreFontSize
    bestScoreLabel.fontColor = SKColor(red: 255.0/255.0, green: 248.0/255.0, blue: 121.0/255.0, alpha: 1.0)
    bestScoreLabel.position = CGPoint(x: scorecard.size.width * 0.20 * aspectRatio, y: -scorecard.size.height * 0.25 * aspectRatio)
    bestScoreLabel.zPosition = Layer.ui.rawValue
    bestScoreLabel.text = "\(self.bestScore())"
    scorecard.addChild(bestScoreLabel)
    
    let bestScoreLabelOutline = SKLabelNode(fontNamed: kFontName)
    bestScoreLabelOutline.fontSize = kScoreFontSize
    bestScoreLabelOutline.fontColor = SKColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    bestScoreLabelOutline.position = CGPoint(x: scorecard.size.width * 0.20 * aspectRatio, y: -scorecard.size.height * 0.25 * aspectRatio)
    bestScoreLabelOutline.zPosition = Layer.ui.rawValue - 1
    bestScoreLabelOutline.text = "\(self.bestScore())"
    scorecard.addChild(bestScoreLabelOutline)
    
    
    let gameOver = SKSpriteNode(imageNamed: NSLocalizedString("GameOverImageName", comment: "Game Over Image Name"))
    gameOver.position = CGPoint(x: size.width/2, y: size.height/2 + scorecard.size.height/2 + 275 + gameOver.size.height/2)
    gameOver.xScale *= aspectRatio
    gameOver.yScale *= aspectRatio
    gameOver.zPosition = Layer.ui.rawValue
    worldNode.addChild(gameOver)
    
    let okButton = SKSpriteNode(imageNamed: "Button")
    okButton.xScale *= aspectRatio
    okButton.yScale *= aspectRatio
    okButton.position = CGPoint(x: size.width/2 - scorecard.size.width/2 + okButton.size.width/2,
      y: size.height/2 - scorecard.size.height/2 - kMargin - okButton.size.height/2)
    okButton.zPosition = Layer.ui.rawValue
    okButton.name = "okButton"
    worldNode.addChild(okButton)
    
    let ok = SKSpriteNode(imageNamed: NSLocalizedString("OKImageName", comment: "OK Image Name"))
    ok.position = CGPoint.zero
    ok.zPosition = Layer.ui.rawValue
    ok.name = "okLabel"
    okButton.addChild(ok)
    
    let shareButton = SKSpriteNode(imageNamed: "Button")
    shareButton.xScale *= aspectRatio
    shareButton.yScale *= aspectRatio
    shareButton.position = CGPoint(x: size.width/2 + scorecard.size.width/2 - shareButton.size.width/2,
      y: size.height/2 - scorecard.size.height/2 - kMargin - shareButton.size.height/2)
    shareButton.zPosition = Layer.ui.rawValue
    shareButton.name = "shareButton"
    worldNode.addChild(shareButton)
    
    let share = SKSpriteNode(imageNamed: NSLocalizedString("ShareImageName", comment: "Share Image Name"))
    share.position = CGPoint.zero
    share.zPosition = Layer.ui.rawValue
    share.name = "shareLabel"
    shareButton.addChild(share)
    
    
    // Game Center buttons Achievements & Leaderboards
    
    let achievementsButton = SKSpriteNode(imageNamed: "Button")
    achievementsButton.xScale *= aspectRatio
    achievementsButton.yScale *= aspectRatio
    achievementsButton.position = CGPoint(x: size.width/2 - scorecard.size.width/2 + okButton.size.width/2,
      y: size.height/2 - scorecard.size.height/2 - (kMargin * 11) - okButton.size.height/2)
    achievementsButton.zPosition = Layer.ui.rawValue
    achievementsButton.name = "achievementsButton"
    worldNode.addChild(achievementsButton)
    
    let achievements = SKSpriteNode(imageNamed: NSLocalizedString("AchievementsImageName",comment: "Achievements Image Name"))
    achievements.position = CGPoint.zero
    achievements.zPosition = Layer.ui.rawValue
    achievements.name = "achievements"
    achievementsButton.addChild(achievements)
    
    let leaderboardButton = SKSpriteNode(imageNamed: "Button")
    leaderboardButton.xScale *= aspectRatio
    leaderboardButton.yScale *= aspectRatio
    leaderboardButton.position = CGPoint(x: size.width/2 + scorecard.size.width/2 - shareButton.size.width/2,
      y: size.height/2 - scorecard.size.height/2 - (kMargin * 11) - shareButton.size.height/2)
    leaderboardButton.zPosition = Layer.ui.rawValue
    leaderboardButton.name = "leaderboardButton"
    worldNode.addChild(leaderboardButton)
    
    let leaderboard = SKSpriteNode(imageNamed: NSLocalizedString("LeaderboardImageName", comment: "Leaderboard Image Name"))
    leaderboard.position = CGPoint.zero
    leaderboard.zPosition = Layer.ui.rawValue
    leaderboard.name = "leaderboard"
    leaderboardButton.addChild(leaderboard)

    
    // Adding some ScoreCard Animations
    
    // Scale in GameOver Message
    gameOver.setScale(0)
    gameOver.alpha = 0
    let group = SKAction.group([
      SKAction.fadeIn(withDuration: kAnimDelay),
      SKAction.scale(to: aspectRatio, duration: kAnimDelay)
      ])
    group.timingMode = .easeInEaseOut
    
    gameOver.run(SKAction.sequence([
      SKAction.wait(forDuration: kAnimDelay),
      group
      ]))
    
    // Slide up ScoreCard
    scorecard.position = CGPoint(x:size.width * 0.5, y: -scorecard.size.height/2)
    let moveTo = SKAction.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.60), duration: kAnimDelay)
    moveTo.timingMode = .easeInEaseOut
    scorecard.run(SKAction.sequence([
      SKAction.wait(forDuration: kAnimDelay * 2),
      moveTo
      ]))
    
    // Fade in Buttons
    okButton.alpha = 0
    shareButton.alpha = 0
    achievementsButton.alpha = 0
    leaderboardButton.alpha = 0
    
    let fadeIn = SKAction.sequence([
      SKAction.wait(forDuration: kAnimDelay * 3),
      SKAction.fadeIn(withDuration: kAnimDelay * 1.5)
      ])
    okButton.run(fadeIn)
    shareButton.run(fadeIn)
    achievementsButton.run(fadeIn)
    leaderboardButton.run(fadeIn)
    
    // Play animation sounds
    let pops = SKAction.sequence([
      SKAction.wait(forDuration: kAnimDelay),
      popAction,
      SKAction.wait(forDuration: kAnimDelay),
      popAction,
      SKAction.wait(forDuration: kAnimDelay),
      popAction,
      SKAction.run(switchToGameOver)
      ])
    run(pops)
    
  }
  
  func setupTutorial() {
    
    let ready = SKSpriteNode(imageNamed: NSLocalizedString("ReadyImageName", comment: "Ready Image Name"))
    ready.setScale(2.0)
    ready.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.75 + playableStart)
    ready.name = "Tutorial"
    ready.zPosition = Layer.ui.rawValue
    worldNode.addChild(ready)
    
    let tutorial = SKSpriteNode(imageNamed: NSLocalizedString("TutorialImageName", comment: "Tutorial Image Name"))
    tutorial.setScale(2.5)
    tutorial.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.4 + playableStart)
    tutorial.name = "Tutorial"
    tutorial.zPosition = Layer.ui.rawValue
    worldNode.addChild(tutorial)
    
    // Animate Ready & Tutorial
    ready.position = CGPoint(x: size.width * 0.5, y: size.height + ready.size.height/2)
    let moveTo = SKAction.move(to: CGPoint(x: size.width * 0.5, y: playableHeight * 0.75 + playableStart), duration: 1.0)
    moveTo.timingMode = .easeInEaseOut
    ready.run(SKAction.sequence([
      SKAction.wait(forDuration: kAnimDelay),
      moveTo
      ]))
    
    let tutorialMoveUp = SKAction.moveBy(x: 0, y: 50, duration: kAnimDelay)
    let tutorialMoveDown = SKAction.moveBy(x: 0, y: -50, duration: kAnimDelay)
    let tutorialMoveUpDown = SKAction.sequence([
      tutorialMoveUp,
      tutorialMoveDown,
      SKAction.wait(forDuration: 0.1)])
    let bouceTutorial = SKAction.repeatForever(tutorialMoveUpDown)
    tutorial.run(bouceTutorial)
    
  }
  
  func setupMainMenu() {
    
    let logo = SKSpriteNode(imageNamed: NSLocalizedString("LogoImageName", comment: "Logo Image Name"))
    logo.setScale(2.0)
    logo.position = CGPoint(x: size.width/2, y: size.height * 0.8)
    logo.zPosition = Layer.ui.rawValue
    logo.name = "logo"
    worldNode.addChild(logo)
    
    // Play Button
    let playButton = SKSpriteNode(imageNamed: "Button")
    playButton.setScale(1.33)
    playButton.position = CGPoint(x: size.width * 0.20 + playButton.size.width/2, y: size.height * 0.30 - kMargin)
    playButton.zPosition = Layer.ui.rawValue
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
    rateButton.zPosition = Layer.ui.rawValue
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
    let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.5)
    moveUp.timingMode = .easeInEaseOut
    let moveDown = SKAction.moveBy(x: 0, y: -50, duration: 0.5)
    moveDown.timingMode = .easeInEaseOut
    
    player.run(SKAction.repeatForever(SKAction.sequence([
      moveUp, moveDown
      ])), withKey: "playerBounce")
    
  }
  
  
  func setupPlayerAnimation() {
    
    var textures: Array<SKTexture> = []
    for i in 0..<kNumPlayerFrames {
      textures.append(SKTexture(imageNamed: "Turtle_Universal_\(i)"))
    }
    for i in stride(from: kNumPlayerFrames, through: 0, by: -1) {
      textures.append(SKTexture(imageNamed: "Turtle_Universal_\(i)"))
    }
    
    let playerAnimation = SKAction.animate(with: textures, timePerFrame: 0.07)
    player.run(SKAction.repeatForever(playerAnimation))
  }
  
  func setupTopObstacleAnimation() {
    
    var textures: Array<SKTexture> = []
    for i in 0..<kNumTopObstacleFrames {
      textures.append(SKTexture(imageNamed: "JellyFish_Universal_\(i)"))
    }
    for i in stride(from: (kNumTopObstacleFrames - 1), through: 0, by: -1) {
      textures.append(SKTexture(imageNamed: "JellyFish_Universal_\(i)"))
    }
    
    let topObstacleAnimation = SKAction.animate(with: textures, timePerFrame: 0.05)
    topObstacle.run(SKAction.repeatForever(topObstacleAnimation))
  }
  
  
  func setupHud() {
    
    musicButtonOn.position = CGPoint(x: size.width * 0.8, y: playableStart - musicButtonOn.size.height - kMargin * 4.0)
    musicButtonOn.setScale(2.0)
    musicButtonOn.alpha = 0.90
    musicButtonOn.zPosition = Layer.ui.rawValue
    musicButtonOn.name = "musicButtonOn"
    worldNode.addChild(musicButtonOn)
    
    musicButtonOff.position = CGPoint(x: size.width * 0.8, y: playableStart - musicButtonOff.size.height - kMargin * 4.0)
    musicButtonOff.setScale(2.0)
    musicButtonOff.alpha = 0.90
    musicButtonOff.zPosition = Layer.ui.rawValue
    musicButtonOff.name = "musicButtonOff"
    musicButtonOff.isHidden = true
    worldNode.addChild(musicButtonOff)
    
  }
  
  // MARK: Gameplay
  
  func createObstacle(_ imageName: String) -> SKSpriteNode {
    let sprite = SKSpriteNode(imageNamed: imageName)
    sprite.zPosition = Layer.obstacle.rawValue
    
    // Setup empty Dictionary for sprites userData
    sprite.userData = NSMutableDictionary()
    
    return sprite
  }
  
  func createTopObstacle() -> SKSpriteNode {
    
    let texture = SKTexture(imageNamed: "JellyFish_Universal_0")
    topObstacle = SKSpriteNode(texture: texture)
    topObstacle.userData = NSMutableDictionary()
    topObstacle.zPosition = Layer.obstacle.rawValue
    
    let offsetX_2 = topObstacle.size.width * topObstacle.anchorPoint.x
    let offsetY_2 = topObstacle.size.height * topObstacle.anchorPoint.y
    
    let path_2 = CGMutablePath()
    
    path_2.move(to: CGPoint(x: 69 - offsetX_2, y: 713 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 30 - offsetX_2, y: 691 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 8 - offsetX_2, y: 649 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 16 - offsetX_2, y: 619 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 38 - offsetX_2, y: 609 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 40 - offsetX_2, y: 561 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 34 - offsetX_2, y: 512 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 35 - offsetX_2, y: 470 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 37 - offsetX_2, y: 419 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 41 - offsetX_2, y: 387 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 60 - offsetX_2, y: 363 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 27 - offsetX_2, y: 342 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 9 - offsetX_2, y: 316 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 7 - offsetX_2, y: 278 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 34 - offsetX_2, y: 264 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 24 - offsetX_2, y: 208 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 18 - offsetX_2, y: 153 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 19 - offsetX_2, y: 116 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 18 - offsetX_2, y: 66 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 26 - offsetX_2, y: 34 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 41 - offsetX_2, y: 37 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 59 - offsetX_2, y: 10 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 72 - offsetX_2, y: 47 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 90 - offsetX_2, y: 47 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 94 - offsetX_2, y: 15 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 113 - offsetX_2, y: 34 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 120 - offsetX_2, y: 53 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 131 - offsetX_2, y: 50 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 136 - offsetX_2, y: 59 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 117 - offsetX_2, y: 148 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 131 - offsetX_2, y: 194 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 163 - offsetX_2, y: 167 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 185 - offsetX_2, y: 197 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 207 - offsetX_2, y: 171 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 230 - offsetX_2, y: 199 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 247 - offsetX_2, y: 220 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 236 - offsetX_2, y: 277 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 226 - offsetX_2, y: 303 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 231 - offsetX_2, y: 341 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 237 - offsetX_2, y: 381 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 225 - offsetX_2, y: 424 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 246 - offsetX_2, y: 439 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 224 - offsetX_2, y: 496 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 173 - offsetX_2, y: 520 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 142 - offsetX_2, y: 528 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 131 - offsetX_2, y: 608 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 152 - offsetX_2, y: 617 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 149 - offsetX_2, y: 660 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 129 - offsetX_2, y: 693 - offsetY_2))
    path_2.addLine(to: CGPoint(x: 99 - offsetX_2, y: 710 - offsetY_2))
    
    path_2.closeSubpath()
    
    topObstacle.physicsBody = SKPhysicsBody(polygonFrom: path_2)
    topObstacle.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
    topObstacle.physicsBody?.collisionBitMask = 0
    topObstacle.physicsBody?.contactTestBitMask = PhysicsCategory.Player
    
    topObstacle.name = "topObstacle"
    
    setupTopObstacleAnimation()
    
    worldNode.addChild(topObstacle)

    return topObstacle
    
  }
  
  func spawnObstacle() {
    
    let bottomObstacle = createObstacle("SeaPlants_Universal")
    let startX = size.width + bottomObstacle.size.width/2
    
    let bottomObstacleMin = (playableStart - bottomObstacle.size.height/2 + playableHeight * kBottomObstacleMinFraction)
    let bottomObstacleMax = (playableStart - bottomObstacle.size.height/2 + playableHeight * kBottomObstacleMaxFraction)
    bottomObstacle.xScale *= size.width / size.height * obstacleScaleFactor
    bottomObstacle.yScale *= size.width / size.height * obstacleScaleFactor
    bottomObstacle.position = CGPoint(x: startX, y: CGFloat.random(min: bottomObstacleMin, max: bottomObstacleMax))
    
    
    let offsetX = bottomObstacle.size.width * bottomObstacle.anchorPoint.x
    let offsetY = bottomObstacle.size.height * bottomObstacle.anchorPoint.y
    
    let path = CGMutablePath()
    
    path.move(to: CGPoint(x: 112 - offsetX, y: 978 - offsetY))
    path.addLine(to: CGPoint(x: 86 - offsetX, y: 948 - offsetY))
    path.addLine(to: CGPoint(x: 55 - offsetX, y: 924 - offsetY))
    path.addLine(to: CGPoint(x: 53 - offsetX, y: 852 - offsetY))
    path.addLine(to: CGPoint(x: 45 - offsetX, y: 728 - offsetY))
    path.addLine(to: CGPoint(x: 59 - offsetX, y: 548 - offsetY))
    path.addLine(to: CGPoint(x: 1 - offsetX, y: 498 - offsetY))
    path.addLine(to: CGPoint(x: 4 - offsetX, y: 467 - offsetY))
    path.addLine(to: CGPoint(x: 37 - offsetX, y: 420 - offsetY))
    path.addLine(to: CGPoint(x: 28 - offsetX, y: 369 - offsetY))
    path.addLine(to: CGPoint(x: 43 - offsetX, y: 241 - offsetY))
    path.addLine(to: CGPoint(x: 45 - offsetX, y: 182 - offsetY))
    path.addLine(to: CGPoint(x: 49 - offsetX, y: 131 - offsetY))
    path.addLine(to: CGPoint(x: 26 - offsetX, y: 115 - offsetY))
    path.addLine(to: CGPoint(x: 31 - offsetX, y: 73 - offsetY))
    path.addLine(to: CGPoint(x: 5 - offsetX, y: 36 - offsetY))
    path.addLine(to: CGPoint(x: 42 - offsetX, y: 39 - offsetY))
    path.addLine(to: CGPoint(x: 58 - offsetX, y: 15 - offsetY))
    path.addLine(to: CGPoint(x: 93 - offsetX, y: 4 - offsetY))
    path.addLine(to: CGPoint(x: 166 - offsetX, y: 13 - offsetY))
    path.addLine(to: CGPoint(x: 148 - offsetX, y: 75 - offsetY))
    path.addLine(to: CGPoint(x: 131 - offsetX, y: 88 - offsetY))
    path.addLine(to: CGPoint(x: 162 - offsetX, y: 136 - offsetY))
    path.addLine(to: CGPoint(x: 162 - offsetX, y: 330 - offsetY))
    path.addLine(to: CGPoint(x: 161 - offsetX, y: 392 - offsetY))
    path.addLine(to: CGPoint(x: 131 - offsetX, y: 402 - offsetY))
    path.addLine(to: CGPoint(x: 149 - offsetX, y: 466 - offsetY))
    path.addLine(to: CGPoint(x: 148 - offsetX, y: 514 - offsetY))
    path.addLine(to: CGPoint(x: 162 - offsetX, y: 651 - offsetY))
    path.addLine(to: CGPoint(x: 173 - offsetX, y: 673 - offsetY))
    path.addLine(to: CGPoint(x: 202 - offsetX, y: 665 - offsetY))
    path.addLine(to: CGPoint(x: 207 - offsetX, y: 695 - offsetY))
    path.addLine(to: CGPoint(x: 163 - offsetX, y: 705 - offsetY))
    path.addLine(to: CGPoint(x: 165 - offsetX, y: 959 - offsetY))
    path.addLine(to: CGPoint(x: 153 - offsetX, y: 995 - offsetY))
    path.addLine(to: CGPoint(x: 141 - offsetX, y: 952 - offsetY))
    path.addLine(to: CGPoint(x: 124 - offsetX, y: 951 - offsetY))
    path.addLine(to: CGPoint(x: 126 - offsetX, y: 965 - offsetY))
    
    path.closeSubpath()
    
    bottomObstacle.physicsBody = SKPhysicsBody(polygonFrom: path)
    bottomObstacle.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
    bottomObstacle.physicsBody?.collisionBitMask = 0
    bottomObstacle.physicsBody?.contactTestBitMask = PhysicsCategory.Player
    
    bottomObstacle.name = "bottomObstacle"
    
    worldNode.addChild(bottomObstacle)
    
    
    topObstacle = createTopObstacle()
    
    
    //let topObstacle = createObstacle("JellyFish_Universal_0")
    topObstacle.position = CGPoint(x: startX, y: bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + player.size.height * kGapMultiplier)
    topObstacle.zPosition = Layer.obstacle.rawValue
    topObstacle.xScale *= size.width / size.height * obstacleScaleFactor
    topObstacle.yScale *= size.width / size.height * obstacleScaleFactor
    
    
    let moveX = size.width + bottomObstacle.size.width
    let moveDuration = moveX / kGroundSpeed
    let sequence = SKAction.sequence([
      SKAction.moveBy(x: -moveX, y: 0, duration: TimeInterval(moveDuration)),
      SKAction.removeFromParent()
      ])
    topObstacle.run(sequence)
    bottomObstacle.run(sequence)
    
  }
  
  func startSpawning() {
    
    let firstDelay = SKAction.wait(forDuration: kFirstSpawnDelay)
    let spawn = SKAction.run(spawnObstacle)
    let everyDelay = SKAction.wait(forDuration: kEverySpawnDelay)
    let spawnSequence = SKAction.sequence([
      spawn, everyDelay
      ])
    let foreverSpawn = SKAction.repeatForever(spawnSequence)
    let overallSequence = SKAction.sequence([firstDelay, foreverSpawn])
    run(overallSequence, withKey: "spawn")
    
  }
  
  func stopSpawning() {
    
    // Stop the spawn creation of obstacles
    removeAction(forKey: "spawn")
    
    // Stop the moving actions of ones already created
    worldNode.enumerateChildNodes(withName: "topObstacle", using: { node, stop in
      node.removeAllActions()
    })
    
    worldNode.enumerateChildNodes(withName: "bottomObstacle", using: { node, stop in
      node.removeAllActions()
    })
    
  }
  
  func flapPlayer() {
    
    // Play sound
    run(flapAction)
    
    playerVelocity = CGPoint(x: 0, y: kImpluse)
    playerAngularVelocity = kAngularVelocity.degreesToRadians()
    lastTouchTime = lastUpdateTime
    lastTouchY = player.position.y
    
    // Move Hat
    let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 0.15)
    moveUp.timingMode = .easeInEaseOut
    let moveDown = moveUp.reversed()
    playerHat.run(SKAction.sequence([ moveUp, moveDown]))
    
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    //    if let touch = touches.first {
    //      print("\(touch)")
    //    }
    
    for touch: AnyObject! in touches {
      let touchLocation = touch.location(in: self)
      let touchedNode = self.atPoint(touchLocation)
      
      switch gameState {
      case .mainMenu:
        if touchedNode.name == "playButton" || touchedNode.name == "playLabel" {
          switchToNewGame(.tutorial)
        }
        if touchedNode.name == "rateButton" || touchedNode.name == "rateLabel" {
          rateApp()
        }
        break
      case .tutorial:
        if touchedNode.name == "musicButtonOn" || touchedNode.name == "musicButtonOff" {
          toggleMusic()
        } else {
          switchToPlay()
        }
        break
      case .play:
        if touchedNode.name == "musicButtonOn" || touchedNode.name == "musicButtonOff" {
          toggleMusic()
        } else {
          flapPlayer()
        }
        break
      case .falling:
        break
      case .showingScore:
        break
      case .gameOver:
        if touchedNode.name == "okButton" || touchedNode.name == "okLabel" {
          switchToNewGame(.mainMenu)
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
  
  override func update(_ currentTime: TimeInterval) {
    
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime
    
    switch gameState {
    case .mainMenu:
      break
    case .tutorial:
      break
    case .play:
      updateForeground()
      updateBackground()
      updatePlayer()
      checkHitObstacle()
      checkHitGround()
      updateScore()
      updateDifficultyLevel()
      break
    case .falling:
      updatePlayer()
      checkHitGround()
      break
    case .showingScore:
      break
    case .gameOver:
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
    
    if gameState == .play {
      
      worldNode.enumerateChildNodes(withName: "foreground", using: { node, stop in
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
    
    if gameState == .play {
      
      worldNode.enumerateChildNodes(withName: "background", using: { node, stop in
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
      run(hitGroundAction)
      switchToShowScore()
    }
    
  }
  
  func updateScore() {
    
    worldNode.enumerateChildNodes(withName: "bottomObstacle", using: { node, stop in
      if let obstacle = node as? SKSpriteNode {
        if let passed = obstacle.userData?["Passed"] as? NSNumber {
          if passed.boolValue {
            return
          }
        }
        if self.player.position.x > obstacle.position.x + obstacle.size.width/2 {
          self.score = self.score + 1
          self.scoreLabel.text = "\(self.score)"
          self.scoreLabelBackground.text = "\(self.score)"
          self.run(self.coinAction)
          obstacle.userData?["Passed"] = NSNumber(value: true as Bool)
          self.checkIfAchievementEarned()
        }
      }
    })
    
  }
  
  func updateDifficultyLevel() {
    
    switch score {
    case 0...9:
      kGapMultiplier    =      1.50
      Gravity           =   -1500.0
      kImpluse          =     600.0
      kAngularVelocity  =     200.0
      kEverySpawnDelay  =       2.5
      break
    case 10...19:
      kGroundSpeed      =     350.0
      kEverySpawnDelay  =       2.75
      break
    case  20...29:
      kImpluse          =     700.0
      kGroundSpeed      =     375.0
      kEverySpawnDelay  =       3.0
      kBackgroundSpeed  =      75.0
      break
    case 30...39:
      kImpluse          =     600.0
      Gravity           =   -1400.0
      kGroundSpeed      =     400.0
      kEverySpawnDelay  =       2.5
      kBackgroundSpeed  =      50.0
      kGapMultiplier    =       2.0
      kAngularVelocity  =      250.0
      break
    case 40...49:
      kGroundSpeed      =      400.0
      kGapMultiplier    =        1.75
      Gravity           =    -1500.0
      kImpluse          =      700.0
      break
    case 50...59:
      kGapMultiplier    =        2.0
      Gravity           =    -1500.0
      kImpluse          =      600.0
      kAngularVelocity  =      200.0
      kEverySpawnDelay  =        2.0
      kGroundSpeed      =      300.0
      break
    case 60...69:
      kGapMultiplier    =        2.0
      Gravity           =    -1550.0
      kImpluse          =      800.0
      kAngularVelocity  =      250.0
      kEverySpawnDelay  =        3.0
      kGroundSpeed      =      350.0
      break
    case 70...79:
      kGapMultiplier    =        1.50
      Gravity           =    -1600.0
      kImpluse          =      800.0
      kAngularVelocity  =      200.0
      kEverySpawnDelay  =        3.5
      kGroundSpeed      =      275.0
      break
    case 80...89:
      kGapMultiplier    =        1.50
      Gravity           =    -1500.0
      kImpluse          =      600.0
      kAngularVelocity  =      200.0
      kEverySpawnDelay  =        2.5
      kAngularVelocity  =      200.0
      kGroundSpeed      =      300.0
      kBackgroundSpeed  =       50.0
      break
    case 90...99:
      kGapMultiplier    =        1.50
      Gravity           =    -1300.0
      kImpluse          =      660.0
      kAngularVelocity  =      250.0
      kEverySpawnDelay  =        4.75
      kAngularVelocity  =      200.0
      kGroundSpeed      =      260.0
      kBackgroundSpeed  =       50.0
      break
    case 100...109:
      kGapMultiplier    =        1.9
      Gravity           =    -1400.0
      kImpluse          =      700.0
      kAngularVelocity  =      200.0
      kEverySpawnDelay  =        4.0
      kAngularVelocity  =      200.0
      kGroundSpeed      =      250.0
      kBackgroundSpeed  =       50.0
      break
    case 110...119:
      kGapMultiplier    =        1.75
      Gravity           =    -1500.0
      kImpluse          =      600.0
      kAngularVelocity  =      200.0
      kEverySpawnDelay  =        2.5
      kAngularVelocity  =      200.0
      kGroundSpeed      =      300.0
      kBackgroundSpeed  =       50.0
      break
    default:
      kGapMultiplier    =      1.50
      Gravity           =   -1500.0
      kImpluse          =     600.0
      kAngularVelocity  =     200.0
      kEverySpawnDelay  =       2.5
      kGroundSpeed      =     300.0
      kBackgroundSpeed  =      50.0
      break
    }
    
  }
  
  // MARK: Game States
  
  func switchToFalling() {
    
    gameState = .falling
    
    // Screen shake
    let shake = SKAction.screenShakeWithNode(worldNode, amount: CGPoint(x: 0, y: 17.0), oscillations: 10, duration: 1.0)
    worldNode.run(shake)
    
    // Flash Screen
    let whiteNode = SKSpriteNode(color: SKColor.white, size: size)
    whiteNode.position = CGPoint(x: size.width/2, y: size.height/2)
    whiteNode.zPosition = Layer.flash.rawValue
    worldNode.addChild(whiteNode)
    
    whiteNode.run(SKAction.removeFromParentAfterDelay(0.01))
    
    run(SKAction.sequence([
      whackAction,
      SKAction.wait(forDuration: 0.1),
      fallingAction
      ]))
    
    player.removeAllActions()
    stopSpawning()
    
  }
  
  func switchToShowScore() {
    
    gameState = .showingScore
    player.removeAllActions()
    stopSpawning()
    musicButtonOn.isHidden = true
    musicButtonOff.isHidden = true
    setupScorecard()
    
  }
  
  func switchToNewGame(_ gameState: GameState) {
    
    run(popAction)
    
    let newScene = GameScene(size: CGSize(width: 1536, height: 2048),delegate: gameSceneDelegate, gameState: gameState)
    newScene.scaleMode = .aspectFill
    let transition = SKTransition.fade(with: SKColor.black, duration: 0.5)
    view?.presentScene(newScene, transition: transition)
    
  }
  
  func switchToGameOver() {
    
    gameState = .gameOver
    
    if isMusicOn == true {
      fadePlayer(backgroundMusicPlayer, fromVolume: 0.4, toVolume: 0.0, overTime: 3.0)
    }
  }
  
  func switchToMainMenu() {
    
    gameState = .mainMenu
    
    setupBackground()
    setupForeground()
    setupPlayer()
  //  setupPlayerHat()
    setupMainMenu()
    setupPlayerAnimation()
   // setupTopObstacleAnimation()
    
  }
  
  func switchToTutorial() {
    
    gameState = .tutorial
    
    setupBackground()
    setupForeground()
    //setupPlayer()
    //setupPlayerHat()
    setupLabel()
    setupHud()
    setupTutorial()
    setupPlayerAnimation()
   // setupTopObstacleAnimation()
    
    if isMusicOn == true {
      playBackgroundMusic("Dancing on Green Grass.mp3")
      musicButtonOn.isHidden = false
      musicButtonOff.isHidden = true
      fadePlayer(backgroundMusicPlayer, fromVolume: 0.0, toVolume: 0.4, overTime: 2.0)
    } else {
      playBackgroundMusic("Dancing on Green Grass.mp3")
      musicButtonOn.isHidden = true
      musicButtonOff.isHidden = false
      stopBackgroundMusic()
      
      //fadePlayer(backgroundMusicPlayer, fromVolume: 0.4, toVolume: 0.0, overTime: 0.0)
    }
    
  }
  
  func switchToPlay() {
    
    // Set state
    gameState = .play
    
    // Remove Tutorial
    worldNode.enumerateChildNodes(withName: "Tutorial", using: { node, stop in
      node.run(SKAction.sequence([
        SKAction.fadeOut(withDuration: 0.3),
        SKAction.removeFromParent()
        ]))
    })
    
    // Stop player bounce
    player.removeAction(forKey: "playerBounce")
    
    // Add Player to scene
    setupPlayer()
    
    // Start spawning
    startSpawning()
    
    
    // Move Player
    flapPlayer()
    
  }
  
  
  
  
  // MARK: Score Card
  
  func bestScore() -> Int {
    return UserDefaults.standard.integer(forKey: "BestScore")
  }
  
  func setBestScore(_ bestScore: Int) {
    UserDefaults.standard.set(bestScore, forKey: "BestScore")
    UserDefaults.standard.synchronize()
  }
  
  func shareScore() {
    
    let urlString = "http://itunes.apple.com/app/id\(kAppStoreID)?mt=8"
    let url = URL(string: urlString)
    
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
    let url = URL(string: urlString)
    UIApplication.shared.openURL(url!)
    
  }
  
  
  // MARK: Physics
  
  func didBegin(_ contact: SKPhysicsContact) {
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
        vc.present(viewController!, animated: true, completion: nil)
      } else {
        print("Authentication is \(GKLocalPlayer.localPlayer().isAuthenticated) ")
        // do something based on the player being logged in.
        
        self.gameCenterAchievements.removeAll()
        self.loadAchievementPercentages()
        
      }
    }
    
  }
  
  func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    
    gameCenterViewController.dismiss(animated: true, completion: nil)
    
    gameCenterAchievements.removeAll()
    loadAchievementPercentages()
    
  }
  
  func showGameCenter(_ viewState: String = "") {
    
    let gameCenterViewController = GKGameCenterViewController()
    
    gameCenterViewController.gameCenterDelegate = self

    // options for what to initially show...
    if viewState == "Achievements" {
      gameCenterViewController.viewState = GKGameCenterViewControllerState.achievements
    } else if viewState == "Leaderboards" {
      gameCenterViewController.leaderboardIdentifier = kLeaderboardID
      gameCenterViewController.viewState = GKGameCenterViewControllerState.leaderboards
    }
    
    let vc:UIViewController = self.view!.window!.rootViewController!
    vc.present(gameCenterViewController, animated: true, completion: nil)
    
  }
  
  func saveHighScore(_ identifier: String, score: Int) {
    
    if (GKLocalPlayer.localPlayer().isAuthenticated) {
      
      let scoreReporter = GKScore(leaderboardIdentifier: identifier)
      
      scoreReporter.value = Int64(score)
      
      scoreReporter.shouldSetDefaultLeaderboard = true
      
      let scoreArray:[GKScore] = [scoreReporter]
      
      GKScore.report(scoreArray, withCompletionHandler: {
        
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
    GKAchievement.loadAchievements(completionHandler: { (allAchievements, error) -> Void in
      
      if error != nil {
        print("Game center could not load achievements, the error is \(error)")
      } else {
        // this could be nil if there was no progress on any achievements thus far
        if (allAchievements != nil) {
          
          for theAchievement in allAchievements! {
            
            if let singleAchievement:GKAchievement = theAchievement as GKAchievement! {
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
  
  func incrementCurrentPercentOfAchievement(_ identifier: String, amount: Double) {
    
    if GKLocalPlayer.localPlayer().isAuthenticated {
      
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
  
  func reportAchievement(_ identifier: String, percentComplete: Double) {
    
    let achievement = GKAchievement(identifier: identifier)
    
    achievement.percentComplete = percentComplete
   
    achievement.showsCompletionBanner = true
    
    let achievementArray:[GKAchievement] = [achievement]
    
    GKAchievement.report(achievementArray, withCompletionHandler: {
      
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
    
    GKAchievement.resetAchievements(completionHandler: {
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
  
  func howManyDaysUntil(_ end: String, start: Date = Date()) -> Int {
    
    //    let start = "01-01-2016"
    //    let end = "12-25-2016"
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd-yyyy"
    
    // let startDate:NSDate = dateFormatter.dateFromString(start)!
    let endDate:Date = dateFormatter.date(from: end)!
    
    let numOfDays = daysBetweenDate(start, endDate: endDate)
    
    print("Number of days: \(numOfDays)")
    return numOfDays
  }
  
  func daysBetweenDate(_ startDate: Date, endDate: Date) -> Int {
    let calendar = Calendar.current
    
    let components = (calendar as NSCalendar).components([.day], from: startDate, to: endDate, options: [])
    
    return components.day!
  }
  
}
