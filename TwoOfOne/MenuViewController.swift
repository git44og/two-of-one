//
//  MenuViewController.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 25/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit

class MenuViewController: UIViewController {
    
    @IBOutlet weak var backgroundFrontView: UIImageView!
    @IBOutlet weak var backgroundBackView: UIImageView!
    @IBOutlet weak var buttonLayerView: UIView!
    @IBOutlet weak var debugPairsSwitch: UISwitch!
    var skipIntro:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let oldCenter = self.backgroundFrontView.center
        let oldFrame = self.backgroundFrontView.frame
        let newOrigin = CGPoint(
            x: oldFrame.origin.x,
            y: oldFrame.size.height * -0.1)
        if(self.skipIntro) {
            self.backgroundFrontView.center = CGPoint(x: oldCenter.x * 2, y: oldCenter.y)
            self.backgroundBackView.frame = CGRect(origin: oldFrame.origin, size: CGSize(width: oldFrame.size.width * 1.2, height: oldFrame.size.height * 1.2))
            return
        }
        
        UIView.animateWithDuration(3.0,
            delay: 0.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { () -> Void in
                self.backgroundFrontView.center = CGPoint(x: oldCenter.x * 2, y: oldCenter.y)
                self.backgroundBackView.frame = CGRect(
                    origin: newOrigin,
                    size: CGSize(width: oldFrame.size.width * 1.2, height: oldFrame.size.height * 1.2))
            }) { (Bool) -> Void in
                print("done")
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func onPlayPressed(sender: AnyObject) {
        
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("gameScreen") as! ViewController

        switch(sender.tag) {
        case 1:
            vc.game.level = 0
            break
        case 2:
            vc.game.level = 1
            break
        case 3:
            vc.game.level = 2
            break
        default:
            break
        }
        
        vc.game.debugPairs = self.debugPairsSwitch.on
        
        self.presentViewController(vc, animated: false) { () -> Void in
            vc.gamePlayIntro()
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.LandscapeLeft
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.LandscapeLeft
    }

}