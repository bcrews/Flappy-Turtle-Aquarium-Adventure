//
//  HelperUtils.swift
//  Flappy Turtle Aquarium Adventure
//
//  Created by Bill Crews on 5/4/16.
//  Copyright © 2016 BC App Designs, LLC. All rights reserved.
//

import SpriteKit
import AVFoundation

var backgroundMusicPlayer: AVAudioPlayer!

func playBackgroundMusic(_ filename: String) {
  
  let resourceUrl = Bundle.main.url(forResource: filename, withExtension: nil)
  guard let url = resourceUrl else {
    print("Could not find file: \(filename)")
    return
  }
  
  do {
    try backgroundMusicPlayer = AVAudioPlayer(contentsOf: url)
    backgroundMusicPlayer.numberOfLoops = -1
    backgroundMusicPlayer.prepareToPlay()
    backgroundMusicPlayer.play()
  } catch {
    print("Could not create audio player!")
    return
  }
}

func stopBackgroundMusic() {
  backgroundMusicPlayer.stop()
}

func fadePlayer(_ player: AVAudioPlayer,fromVolume startVolume : Float,
                toVolume endVolume : Float, overTime time : Float) {
  
  // Update the volume every 1/100 of a second
  let fadeSteps: Int = Int(time) * 100
  
  // Work out how much time each step will take
  let timePerStep : Float = 1 / 100.0
  
  player.volume = startVolume
  
  // Schedule a number of volume changes
  for step in 0...fadeSteps {
    
    let delayInSeconds: Float = Float(step) * timePerStep
    
    let popTime = DispatchTime.now() + Double(Int64(delayInSeconds * Float(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: popTime) {
      
      let fraction = (Float(step) / Float(fadeSteps))
      
      player.volume = startVolume + (endVolume - startVolume) * fraction
      
    }
  }
}


