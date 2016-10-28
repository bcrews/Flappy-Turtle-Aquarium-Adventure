//
//  GameViewController.swift
//  Flappy Turtle Aquarium Adventure
//
//  Created by Bill Crews on 1/7/16.
//  Copyright (c) 2016 BC App Designs, LLC. All rights reserved.
//

import UIKit
import SpriteKit
import iAd
import GameKit

class GameViewController: UIViewController, GameSceneDelegate, ADBannerViewDelegate {
  
  @IBOutlet weak var iadBanner: ADBannerView!
  
  override func viewWillLayoutSubviews() {
    
    super.viewWillLayoutSubviews()
    
    if let skView = self.view as? SKView {
      if skView.scene == nil {
        
        // Create the scene
        let scene = GameScene(size: CGSize(width: 1536, height: 2048), delegate: self, gameState: .mainMenu)
        
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsPhysics = false
        skView.ignoresSiblingOrder = true
        
        scene.scaleMode = .aspectFill

//        iadBanner.delegate = self
//        iadBanner.isHidden = true
//        skView.addSubview(iadBanner)
      
        skView.presentScene(scene)
        
      }
      
      
      
    }
  }
  
  override var prefersStatusBarHidden : Bool {
    return true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // MARK: Delegate methods for AdBannerView
  
  func bannerViewDidLoadAd(_ banner: ADBannerView!) {
    iadBanner.isHidden = false
  }

  func bannerView(_ banner: ADBannerView!, didFailToReceiveAdWithError error: Error!) {
    print("\(error)")
    iadBanner.isHidden = true
  }
  
  func bannerViewActionShouldBegin(_ banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
    return true
  }
  
  
  // MARK: Implemented functions
  
  func screenShot() -> UIImage {
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 1.0)
    view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
    
  }
  
  func shareString(_ string: String, url: URL, image: UIImage) {
    
    let vc = UIActivityViewController(activityItems: [string, url, image], applicationActivities: nil)
    
    // if iPhone
    if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
    
      present(vc, animated: true, completion: nil)
    }
    // iPad
    else {
      let popup: UIPopoverController = UIPopoverController(contentViewController: vc)
      popup.present(from: CGRect(x: self.view.frame.width * 0.68, y: self.view.frame.height * 0.68,width: 0,height: 0), in: self.view, permittedArrowDirections: UIPopoverArrowDirection.down, animated: true)
    }
  }
 

  
}




