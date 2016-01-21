//
//  JFUtils.swift
//  TwoOfOne
//
//  Created by Jens on 7/09/2015.
//  Copyright (c) 2015 Jens. All rights reserved.
//

import Foundation
import SceneKit

func JFrand(count: Int) -> Int {
    return Int(arc4random_uniform(UInt32(count)))
}

func execDelay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func execOnMain(closure:()->()) {
    dispatch_async(dispatch_get_main_queue(), {
        closure()
    })
}

func isFirstLaunch(maxLaunch:Int = 1) -> Bool {
    
    let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    var numLaunched: Int? = userDefaults.objectForKey("numbersLaunched") as? Int
    if (numLaunched == nil) {
        numLaunched = 1
        userDefaults.setInteger(1, forKey: "numbersLaunched")
    } else {
        numLaunched = numLaunched! + 1
        userDefaults.setInteger(numLaunched!, forKey: "numbersLaunched")
    }
    
    return (numLaunched! <= maxLaunch)
}

func shuffleList<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
    let c = list.count
    for i in 0..<(c - 1) {
        let j = Int(arc4random_uniform(UInt32(c - i))) + i
        if(i != j) {
            swap(&list[i], &list[j])
        }
    }
    return list
}

// reduces angle to bounds ]-pi,+pi[
func normalizeAngle(angle:Float) -> Float {
    var normAngle = angle
    while(normAngle > Float(M_PI)) {
        normAngle -= Float(M_PI * 2)
    }
    while(normAngle < -Float(M_PI)) {
        normAngle += Float(M_PI * 2)
    }
    return normAngle
}

// returns y rotation with positive y vector
func normalizeRotationY(rotation:SCNVector4) -> Float {
    if(rotation.y > 0.5) {
        return rotation.w
    } else if(rotation.y < -0.5) {
        return -rotation.w
    }
    return 0
}

// limits angle to top / bottom
// slows angleSpeed towards limits
func easeAngle(angle:Double, maxTop:Double, maxBottom:Double) -> Double {
    if((angle >= 0) && (angle < maxTop)) {
        return sin((angle / maxTop) * M_PI_2) * maxTop
    } else if((angle > maxBottom) && (angle < 0)) {
        return sin((angle / maxBottom) * M_PI_2) * maxBottom
    } else if(angle >= maxTop) {
        return maxTop
    } else if(angle <= maxBottom) {
        return maxBottom
    }
    return angle
}

//MARK: Math

func sign(number:Float) -> Float {
    return (number < 0) ? -1 : +1
}

//MARK: Formatting

func formatTime(value:Int) -> String {
    let hour = value / 3600
    let minute = (value / 60) % 60
    let second = value % 60
    var hourStr = ""
    var minuteStr = ""
    var secondStr = ""
    if(hour > 0) {
        hourStr = (hour > 0) ? "\(hour):" : ""
        minuteStr = (minute > 9) ? "\(minute)" : ((minute > 0) ? "0\(minute)" : "00")
        secondStr = ""
    } else {
        minuteStr = (minute > 9) ? "\(minute):" : ((minute > 0) ? "0\(minute):" : "00:")
        secondStr = (second > 9) ? "\(second)" : ((second > 0) ? "0\(second)" : "00")
    }
    return "\(hourStr)\(minuteStr)\(secondStr)"
}

// adm tracking utils

let kTrackingPrefix = "twoofone"

enum ADMTrackingDataKeys: String {
    case gcLoggedIn = "gameCenter.loginStatus"
    case appNumLaunched = "app.numLaunched"
    case gameScore = "game.score"
    case gameLevel = "game.level"
    
    func name() -> String {
        return "\(kTrackingPrefix).\(self.rawValue)"
    }
}

enum ADMTrackingState: String {
    case gamePlaying = "Game"
    case menuHome = "Home"
    case gameCenterChallenge = "GCChallenge"
    case gameCenterLeaderboard = "GCLeaderBoard"
    
    func name() -> String {
        return "\(self.rawValue)"
    }
}

enum ADMTrackingAction: String {
    case gamePlay = "game.playGame"
    case gamePlayAgain = "game.playAgain"
    case gameFinish = "game.gameOver"
    case gameExit = "game.exitGame"
    
    case gameCenter = "gamecenter.access"
    case gameCenterLogin = "gamecenter.login"
    case gameCenterLeaderboard = "gamecenter.leaderboard"
    
    case gameCenterChallenge = "gamecenter.challenge"
    case gameCenterChallengeSuccess = "gamecenter.challenge.success"
    
    case shareFacebookPressed = "share.facebook.pressed"
    case shareFacebookSuccess = "share.facebook.success"
    case shareFacebookCancel = "share.facebook.cancel"
    case shareTwitterPressed = "share.twitter.pressed"
    case shareTwitterSuccess = "share.twitter.success"
    case shareTwitterCancel = "share.twitter.cancel"
    
    func name() -> String {
        return "\(kTrackingPrefix).\(self.rawValue)"
    }
}

func admTrackState(state:ADMTrackingState, score:Int? = nil, level:Int? = nil) {
    admTrackState(state.name(), score:score, level:level)
}

func admTrackState(stateName:String, score:Int? = nil, level:Int? = nil) {
    let data = admParamHelper(score: score, level: level)
    
    ADBMobile.trackState(stateName, data: data)
}

func admTrackAction(action:ADMTrackingAction, score:Int? = nil, level:Int? = nil) {
    admTrackAction(action.name(), score:score, level:level)
}

func admTrackAction(actionName:String, score:Int? = nil, level:Int? = nil) {
    let data = admParamHelper(score: score, level: level)
    
    ADBMobile.trackAction(actionName, data: data)
}

func admParamHelper(score score:Int? = nil, level:Int? = nil) -> [String: String] {
    var returnDict:[String: String] = [:]
    let gch = CPHGameCenterHelper.sharedInstance
    let loggedIn = gch.gameCenterActive()
    returnDict[ADMTrackingDataKeys.gcLoggedIn.name()] = (loggedIn ? "yes" : "no")
    
    let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    var numLaunched: Int? = userDefaults.objectForKey("numbersLaunched") as? Int
    if (numLaunched == nil) {
        numLaunched = 1
    }
    returnDict[ADMTrackingDataKeys.appNumLaunched.name()] = String(numLaunched!)
    
    if(score != nil) {
        returnDict[ADMTrackingDataKeys.gameScore.name()] = String(score!)
    }
    
    if(level != nil) {
        returnDict[ADMTrackingDataKeys.gameLevel.name()] = String(level!)
    }
    
    return returnDict
}

// class to preload images
class JFImageLoader : NSObject {
    
    static let sharedInstance = JFImageLoader()
    var images:[String:UIImage] = [:]
    
    override init() {
        super.init()
        
        // load score images
        for i in 1 ... 16 {
            let imageId = i * 5
            let imageName = "\(imageId)_Points"
            self.images[imageName] = UIImage(named: imageName)
        }
    }
}
