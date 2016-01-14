//
//  MenuViewController.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 25/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit

let kOptionsEnableBackOfTile = "enableBackOfTile"
let kOptionsEnableDebug = "enableDebug"


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

class MenuViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var backgroundFrontView: UIImageView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var backgroundBackView: UIImageView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var buttonLayerView: UIView!
    @IBOutlet weak var debugPairsSwitch: UISwitch!
    @IBOutlet weak var enableBackOfTile: UISwitch!
    @IBOutlet weak var menuView: JFMenuView!
    
    var menuAnimation:JFMenuAnimation = .Startup
    var animationRefCenter = CGPoint()
    var animationRefFrame = CGRect()

    var debugParTime:Int = 120
    var debugParTurns:Int = 40
    
    override func viewDidLoad() {
        
        let backImage = UIImageView(image: UIImage(named: "Start-Hintergrund.png"))
        backImage.contentMode = UIViewContentMode.ScaleAspectFill
        self.backgroundBackView = backImage
        self.backView.addSubview(self.backgroundBackView)
        
        let frontImage = UIImageView(image: UIImage(named: "Start-Tonne.png"))
        frontImage.contentMode = UIViewContentMode.ScaleAspectFill
        self.backgroundFrontView = frontImage
        self.frontView.addSubview(self.backgroundFrontView)
        
        super.viewDidLoad()
        
        let gch:CPHGameCenterHelper = CPHGameCenterHelper.sharedInstance
        gch.authenticateLocalPlayer(self)

        JFHighScoreObject.sharedInstance.load()
        self.menuView.vc = self
        
        self.enableBackOfTile.on = NSUserDefaults.standardUserDefaults().boolForKey(kOptionsEnableBackOfTile)
        self.debugPairsSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(kOptionsEnableDebug)
        
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
        
        admTrackState(ADMTrackingState.menuHome)
        
        self.backgroundBackView.frame = self.backView.frame
        self.backgroundFrontView.frame = self.frontView.frame

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

    
    func onPlayPressed(sender:AnyObject, level:JFGameLevel) {
        
        admTrackAction(ADMTrackingAction.gamePlay, level:level.rawValue)
        
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("gameScreen") as! ViewController
        vc.game.level = level
        vc.game.parTurns = self.debugParTurns
        vc.game.parTime = NSTimeInterval(self.debugParTime)
        vc.game.enableBackOfTiles = self.enableBackOfTile.on
        vc.game.debugPairs = self.debugPairsSwitch.on
        
        self.animation(.Ready, endState: .Playing) { () -> Void in
            self.presentViewController(vc, animated: false, completion: nil)
        }
    }
    
    func onGameCenterPressed(sender:AnyObject) {
        
        admTrackAction(ADMTrackingAction.gameCenter)
        
        let gch = CPHGameCenterHelper.sharedInstance
        gch.showLeaderBoard(self, level: JFGameLevel.Expert)
    }
    
    @IBAction func onSwitchChange(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setBool(self.enableBackOfTile.on, forKey: kOptionsEnableBackOfTile)
        NSUserDefaults.standardUserDefaults().setBool(self.debugPairsSwitch.on, forKey: kOptionsEnableDebug)
        NSUserDefaults.standardUserDefaults().synchronize()
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
        
        switch(endState) {
        case .Playing:
            UIView.animateWithDuration(duration,
                delay: 0,
                options: option,
                animations: { () -> Void in
                    self.backgroundFrontView.alpha = 0
                    self.backgroundBackView.alpha = 0
                    self.backgroundFrontView.center = CGPoint(x: self.animationRefCenter.x * 10, y: self.animationRefCenter.y)
                    self.backgroundBackView.frame = CGRect(
                        origin: self.animationRefFrame.origin,
                        size: CGSize(width: self.animationRefFrame.size.width * 6, height: self.animationRefFrame.size.height * 6))
                }) { (Bool) -> Void in
                    execDelay(0, closure: { () -> () in
                        if let myCompletion = completion {
                            myCompletion()
                        }
                    })
            }
            UIView.animateWithDuration((duration / 2),
                delay: 0,
                options: UIViewAnimationOptions.CurveEaseOut,
                animations: { () -> Void in
                    self.buttonLayerView.alpha = 0
                },
                completion:nil)
            break
        case .Ready:
            UIView.animateWithDuration(duration,
                delay: 0,
                options: option,
                animations: { () -> Void in
                    self.backgroundFrontView.alpha = 1
                    self.backgroundBackView.alpha = 1
                    self.backgroundFrontView.center = CGPoint(x: self.animationRefCenter.x * 2, y: self.animationRefCenter.y)
                    self.backgroundBackView.frame = CGRect(
                        origin: self.animationRefFrame.origin,
                        size: CGSize(width: self.animationRefFrame.size.width * 1.2, height: self.animationRefFrame.size.height * 1.2))
                }) { (Bool) -> Void in
                    execDelay(0, closure: { () -> () in
                        if let myCompletion = completion {
                            myCompletion()
                        }
                    })
            }
            UIView.animateWithDuration((duration / 2),
                delay: (duration / 2),
                options: UIViewAnimationOptions.CurveEaseIn,
                animations: { () -> Void in
                    self.buttonLayerView.alpha = 1
                },
                completion:nil)
            break
        default:
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
            break
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch(textField.tag) {
        case 10:
            if let myParTime = Int(textField.text!) {
                if(myParTime < 1) {
                    UIAlertView(title: "Error", message: "Wert muss grösser 0 sein", delegate: nil, cancelButtonTitle: "OK").show()
                } else {
                    self.debugParTime = myParTime
                }
            } else {
                UIAlertView(title: "Error", message: "Erwartet Zahl", delegate: nil, cancelButtonTitle: "OK").show()
            }
            break
        case 11:
            if let myParTime = Int(textField.text!) {
                if(myParTime < 1) {
                    UIAlertView(title: "Error", message: "Wert muss grösser 0 sein", delegate: nil, cancelButtonTitle: "OK").show()
                } else {
                    self.debugParTurns = myParTime
                }
            } else {
                UIAlertView(title: "Error", message: "Erwartet Zahl", delegate: nil, cancelButtonTitle: "OK").show()
            }
            break
        default:
            break
        }
        textField.resignFirstResponder()
        return true
    }
}
