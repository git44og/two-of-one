//
//  JFMenuView.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 09/12/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit


let kTitleFontName = "HelveticaNeue"
let kHighScoreFontName = "HelveticaNeue-Light"

class JFMenuView : UIView {
    
    var vc:MenuViewController!
    var playEasyButton:UIButton
    var playMediumButton:UIButton
    var playExpertButton:UIButton
    var gameCenterButton:UIButton
    
    required init?(coder aDecoder: NSCoder) {
        
        self.playEasyButton = UIButton(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
        self.playMediumButton = UIButton(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
        self.playExpertButton = UIButton(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
        self.gameCenterButton = UIButton(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
        
        super.init(coder: aDecoder)
        
        self.addSubview(self.playEasyButton)
        self.playEasyButton.tag = 1
        self.playEasyButton.setBackgroundImage(UIImage(named: "Easy_up"), forState: .Normal)
        self.playEasyButton.setBackgroundImage(UIImage(named: "Easy_down"), forState: .Highlighted)
        self.playEasyButton.addTarget(self, action: Selector("onButtonPressed:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.addSubview(self.playMediumButton)
        self.playMediumButton.tag = 2
        self.playMediumButton.setBackgroundImage(UIImage(named: "Medium_up"), forState: .Normal)
        self.playMediumButton.setBackgroundImage(UIImage(named: "Medium_down"), forState: .Highlighted)
        self.playMediumButton.addTarget(self, action: Selector("onButtonPressed:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.addSubview(self.playExpertButton)
        self.playExpertButton.tag = 3
        self.playExpertButton.setBackgroundImage(UIImage(named: "Expert_up"), forState: .Normal)
        self.playExpertButton.setBackgroundImage(UIImage(named: "Expert_down"), forState: .Highlighted)
        self.playExpertButton.addTarget(self, action: Selector("onButtonPressed:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.addSubview(self.gameCenterButton)
        self.gameCenterButton.setBackgroundImage(UIImage(named: "GameCenter_up"), forState: .Normal)
        self.gameCenterButton.setBackgroundImage(UIImage(named: "GameCenter_down"), forState: .Highlighted)
        self.gameCenterButton.addTarget(self, action: Selector("onButtonPressed:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        var label = UILabel()
        label.tag = 101
        label.text = "Level"
        label.textColor = UIColor.whiteColor()
        label.backgroundColor = UIColor.clearColor()
        self.addSubview(label)
        
        label = UILabel()
        label.tag = 102
        label.text = "High Score"
        label.textColor = UIColor.whiteColor()
        label.backgroundColor = UIColor.clearColor()
        self.addSubview(label)
        
        for i in 0...2 {
            label = UILabel()
            label.tag = 111 + i
            label.text = ["Easy", "Medium", "Expert"][i]
            label.textColor = UIColor.lightGrayColor()
            label.backgroundColor = UIColor.clearColor()
            self.addSubview(label)
        }
        
        for i in 0...2 {
            label = UILabel()
            label.tag = 121 + i
            label.text = String(JFHighScoreObject.sharedInstance.score(i))
            label.textAlignment = .Right
            label.textColor = UIColor.whiteColor()
            label.backgroundColor = UIColor.clearColor()
            self.addSubview(label)
        }
    }
    
    
    //MARK: button actions
    
    override func layoutSubviews() {
        let scale:CGFloat = self.bounds.width / 424
        self.playEasyButton.frame = CGRect(x: 12 * scale, y: 100 * scale, width: 400 * scale, height: 80 * scale)
        self.playMediumButton.frame = CGRect(x: 12 * scale, y: 196 * scale, width: 400 * scale, height: 80 * scale)
        self.playExpertButton.frame = CGRect(x: 12 * scale, y: 292 * scale, width: 400 * scale, height: 80 * scale)
        self.gameCenterButton.frame = CGRect(x: 12 * scale, y: 640 * scale, width: 400 * scale, height: 80 * scale)
        
        // title: Level
        if let label = self.viewWithTag(101) as? UILabel {
            label.font = UIFont(name: kTitleFontName, size: 28 * scale)
            label.frame = CGRect(x: 33 * scale, y: 39 * scale, width: 358 * scale, height: 35 * scale)
        }
        // title: High Score
        if let label = self.viewWithTag(102) as? UILabel {
            label.font = UIFont(name: kTitleFontName, size: 28 * scale)
            label.frame = CGRect(x: 33 * scale, y: 424 * scale, width: 358 * scale, height: 35 * scale)
        }
        
        for i in 0...2 {
            if let label = self.viewWithTag(111 + i) as? UILabel {
                label.font = UIFont(name: kHighScoreFontName, size: 28 * scale)
                label.frame = CGRect(x: 29 * scale, y: CGFloat(483 + (45 * i)) * scale, width: 183 * scale, height: 35 * scale)
            }
            if let label = self.viewWithTag(121 + i) as? UILabel {
                label.font = UIFont(name: kTitleFontName, size: 28 * scale)
                label.frame = CGRect(x: 212 * scale, y: CGFloat(483 + (45 * i)) * scale, width: 183 * scale, height: 35 * scale)
            }
        }
    }
    
    func onButtonPressed(sender:AnyObject) {
        if let senderButton = sender as? UIButton {
            switch(senderButton) {
            case self.playEasyButton:
                vc.onPlayPressed(senderButton, level:0)
                break
            case self.playMediumButton:
                vc.onPlayPressed(senderButton, level:1)
                break
            case self.playExpertButton:
                vc.onPlayPressed(senderButton, level:2)
                break
            case self.gameCenterButton:
                vc.onGameCenterPressed(senderButton)
                break
            default:
                // invalid sender
                break
            }
        }
    }
}

let kPersonalHighScore = "pScore"

class JFHighScoreObject {
    
    var personalScores:[Int] = [0, 0, 0]
    
    class var sharedInstance: JFHighScoreObject {
        struct Static {
            static var instance: JFHighScoreObject?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = JFHighScoreObject()
        }
        
        return Static.instance!
    }

    init() {
        self.load()
    }

    //MARK: accessors
    func setScore(score:Int, level:Int) -> Bool {
        if(self.personalScores.count > level) {
            self.personalScores[level] = score
            self.save()
            return true
        }
        return false
    }
    
    func score(level:Int) -> Int {
        if(self.personalScores.count > level) {
            return self.personalScores[level]
        }
        return 0
    }
    
    //MARK: load/save
    func load() {
        if let pScores = NSUserDefaults.standardUserDefaults().objectForKey(kPersonalHighScore) as? NSArray {
            for i in 0...2 {
                if let score = pScores.objectAtIndex(i) as? NSNumber {
                    self.personalScores[i] = score.integerValue
                }
            }
        } else {
            self.personalScores = [0, 0, 0]
        }
    }
    
    func save() {
        let pScores = NSMutableArray()
        for i in 0...2 {
            let score = NSNumber(integer: self.personalScores[i])
            pScores.addObject(score)
        }
        NSUserDefaults.standardUserDefaults().setObject(pScores, forKey: kPersonalHighScore)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
