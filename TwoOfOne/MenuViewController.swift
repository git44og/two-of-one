//
//  MenuViewController.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 25/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit



enum JFMenuState:Int {
    case PreLaunch = 0
    case Ready
    case Playing
}

enum JFMenuAnimation:Int {
    case None = 0
    case Startup
    case GameEnd
}

class MenuViewController: UIViewController {
    
    @IBOutlet weak var backgroundFrontView: UIImageView!
    @IBOutlet weak var backgroundBackView: UIImageView!
    @IBOutlet weak var buttonLayerView: UIView!
    @IBOutlet weak var debugPairsSwitch: UISwitch!
    @IBOutlet weak var menuView: JFMenuView!
    
    var menuAnimation:JFMenuAnimation = .Startup
    var animationRefCenter = CGPoint()
    var animationRefFrame = CGRect()

    override func viewDidLoad() {
        super.viewDidLoad()
        JFHighScoreObject.sharedInstance.load()
        self.menuView.vc = self
        
        switch(self.menuAnimation) {
        case .None:
            self.applyMenuState(.Ready)
            break
        case .Startup:
            self.applyMenuState(.PreLaunch)
            break
        case .GameEnd:
            self.applyMenuState(.Playing)
            break
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.animationRefCenter = self.backgroundFrontView.center
        self.animationRefFrame = self.backgroundBackView.frame

        switch(self.menuAnimation) {
        case .None:
            self.applyMenuState(.Ready)
            break
        case .Startup:
            self.animation(.PreLaunch, endState: .Ready, completion: nil)
            break
        case .GameEnd:
            self.animation(.Playing, endState: .Ready, completion: nil)
            break
        }
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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

    
    func onPlayPressed(sender:AnyObject, level:Int) {
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("gameScreen") as! ViewController
        vc.game.level = level
        vc.game.debugPairs = self.debugPairsSwitch.on
        
        self.animation(.Ready, endState: .Playing) { () -> Void in
            self.presentViewController(vc, animated: false, completion: nil)
        }
    }
    
    func onGameCenterPressed(sender:AnyObject) {
        print("load gamecenter")
    }
    

    func applyMenuState(state:JFMenuState) {
        switch(state) {
        case .PreLaunch:
            self.buttonLayerView.alpha = 0
            self.backgroundFrontView.alpha = 1
            self.backgroundBackView.alpha = 1
            self.backgroundFrontView.center = animationRefCenter
            self.backgroundBackView.frame = animationRefFrame
            break
        case .Ready:
            self.buttonLayerView.alpha = 1
            self.backgroundFrontView.alpha = 1
            self.backgroundBackView.alpha = 1
            self.backgroundFrontView.center = CGPoint(x: animationRefCenter.x * 2, y: animationRefCenter.y)
            self.backgroundBackView.frame = CGRect(
                origin: animationRefFrame.origin,
                size: CGSize(width: animationRefFrame.size.width * 1.2, height: animationRefFrame.size.height * 1.2))
            break
        case .Playing:
            self.buttonLayerView.alpha = 0
            self.backgroundFrontView.alpha = 0
            self.backgroundBackView.alpha = 0
            self.backgroundFrontView.center = CGPoint(x: animationRefCenter.x * 10, y: animationRefCenter.y)
            self.backgroundBackView.frame = CGRect(
                origin: animationRefFrame.origin,
                size: CGSize(width: animationRefFrame.size.width * 6, height: animationRefFrame.size.height * 6))
            break
        }
    }
    
    func animation(startState:JFMenuState, endState:JFMenuState, completion: (() -> Void)?) {
        
        var duration:Double = 1
        var option = UIViewAnimationOptions.CurveEaseIn
        
        self.applyMenuState(startState)
        switch(startState) {
        case .Playing:
            duration = 1
            option = UIViewAnimationOptions.CurveEaseOut
            break
        case .PreLaunch:
            duration = 2
            option = UIViewAnimationOptions.CurveEaseInOut
            break
        case .Ready:
            duration = 1
            option = UIViewAnimationOptions.CurveEaseIn
            break
        }
        
        UIView.animateWithDuration(duration,
            delay: 0,
            options: option,
            animations: { () -> Void in
                self.applyMenuState(endState)
            }) { (Bool) -> Void in
                execDelay(0, closure: { () -> () in
                    if let myCompletion = completion {
                        myCompletion()
                    }
                })
        }
    }
}
