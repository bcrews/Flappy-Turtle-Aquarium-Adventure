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

class GameViewController: UIViewController, GameSceneDelegate, ADBannerViewDelegate {
  
  @IBOutlet weak var iadBanner: ADBannerView!
  
  override func viewWillLayoutSubviews() {
    
    super.viewWillLayoutSubviews()
    
    if let skView = self.view as? SKView {
      if skView.scene == nil {
        
        // Create the scene
        let scene = GameScene(size: CGSize(width: 1536, height: 2048), delegate: self, gameState: .MainMenu)
        
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsPhysics = false
        skView.ignoresSiblingOrder = true
        
        scene.scaleMode = .AspectFill

        iadBanner.delegate = self
        iadBanner.hidden = true
        skView.addSubview(iadBanner)

        skView.presentScene(scene)
      }
      
      
      
    }
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // MARK: Delegate methods for AdBannerView
  
  func bannerViewDidLoadAd(banner: ADBannerView!) {
    iadBanner.hidden = false
  }

  func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
    print("\(error)")
    iadBanner.hidden = true
  }
  
  func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
    return true
  }
  
  
  // MARK: Implemented functions
  
  func screenShot() -> UIImage {
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 1.0)
    view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
    
  }
  
  func shareString(string: String, url: NSURL, image: UIImage) {
    
    let vc = UIActivityViewController(activityItems: [string, url, image], applicationActivities: nil)
    
    // if iPhone
    if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Phone {
    
      presentViewController(vc, animated: true, completion: nil)
    }
    // iPad
    else {
      let popup: UIPopoverController = UIPopoverController(contentViewController: vc)
      popup.presentPopoverFromRect(CGRectMake(self.view.frame.width * 0.68, self.view.frame.height * 0.68,0,0), inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Down, animated: true)
    }
  }
 

  
}




