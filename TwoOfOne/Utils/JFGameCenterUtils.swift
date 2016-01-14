//
//  JFGameCenterUtils.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 10/01/16.
//  Copyright © 2016 Jens. All rights reserved.
//

import Foundation
import GameKit

let kHighScoreLeaderboardIdentifier:[JFGameLevel: String] = [
    JFGameLevel.Beginner: "com.jfischer77.twoofone.classic.beginner",
    JFGameLevel.Medium: "com.jfischer77.twoofone.classic.medium",
    JFGameLevel.Expert: "com.jfischer77.twoofone.classic.expert"]


class CPHGameCenterHelper : NSObject, GKGameCenterControllerDelegate {
    
    static let sharedInstance = CPHGameCenterHelper()
    var lastError:NSError?
    var gameCenterFeaturesEnabled:Bool = false
    
    override init() {
        super.init()
        
    }
    
    func authenticateLocalPlayer(rootViewController:UIViewController) {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {(viewController:UIViewController?, error:NSError?) -> Void in
            self.lastError = error
            if(localPlayer.authenticated) {
                //println("logged in")
                admTrackAction(ADMTrackingAction.gameCenterLoginSuccess)
                self.gameCenterFeaturesEnabled = true
            } else if(viewController != nil) {
                //println("login screen")
                admTrackAction(ADMTrackingAction.gameCenterLogin)
                rootViewController.presentViewController(viewController!, animated: true, completion: { () -> Void in
                    //println("No viewcontroller to present dialog")
                })
            } else {
                //println("not logged in")
                admTrackAction(ADMTrackingAction.gameCenterLoginCancel)
                self.gameCenterFeaturesEnabled = false
            }
        }
        //((UIViewController!, NSError!) -> Void)!
    }
    
    func gameCenterActive() -> Bool {
        let localPlayer = GKLocalPlayer.localPlayer()
        return localPlayer.authenticated
    }
    
    func showLeaderBoard(viewController:UIViewController) {
        let gcViewController: GKGameCenterViewController = GKGameCenterViewController()
        gcViewController.leaderboardIdentifier = kHighScoreLeaderboardIdentifier[JFGameLevel.Beginner]!
        gcViewController.viewState = GKGameCenterViewControllerState.Leaderboards
        gcViewController.gameCenterDelegate = self
        viewController.presentViewController(gcViewController, animated: true, completion:nil)
        
        //admTrackState(ADMTrackingState.gameCenterLeaderboard)
    }
    
    func challenge(viewController:UIViewController) {
        //admTrackState(ADMTrackingState.gameCenterChallenge)
        if(!self.gameCenterActive()) {
            admTrackAction(ADMTrackingAction.gameCenterChallengeFailNotLoggedIn)
            let alertView = UIAlertController(title: "Game Center Unavailable", message: "Player is not signed in", preferredStyle: UIAlertControllerStyle.Alert);
            alertView.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil));
            viewController.presentViewController(alertView, animated: true, completion: nil);
            return
        }
        let gkScore:GKScore = GKScore(leaderboardIdentifier: kHighScoreLeaderboardIdentifier[JFGameLevel.Beginner]!)
        let challengeVC = gkScore.challengeComposeControllerWithMessage("Try to beat this.", players: []) { (composeController:UIViewController, didIssueChallenge:Bool, sentPlayerIDs:[String]?) -> Void in
            if(didIssueChallenge) {
                admTrackAction(ADMTrackingAction.gameCenterChallengeSuccess)
            } else {
                admTrackAction(ADMTrackingAction.gameCenterChallengeCancel)
            }
            if let rootVc = composeController.presentingViewController {
                rootVc.dismissViewControllerAnimated(true, completion: { () -> Void in
                    //print("dismissed")
                })
            } else {
                viewController.dismissViewControllerAnimated(true, completion: { () -> Void in
                    //print("dismissed by delegate")
                })
            }
        }
        viewController.presentViewController(challengeVC, animated: true, completion: { () -> Void in
            //print("done")
        })
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        if let rootVc = gameCenterViewController.presentingViewController {
            rootVc.dismissViewControllerAnimated(true, completion: { () -> Void in
                //print("view controller dismissed")
            })
        }
    }
    
    func submitScore(score:Int64) {
        if(!self.gameCenterActive()) {
            //print("Player not authenticated")
            return
        }
        
        let gkScore:GKScore = GKScore(leaderboardIdentifier: kHighScoreLeaderboardIdentifier[JFGameLevel.Beginner]!)
        gkScore.value = score
        GKScore.reportScores([gkScore], withCompletionHandler: { (error:NSError?) -> Void in
            self.lastError = error
            let success = error == nil
            if(success) {
                // could callback for successful submission
            }
        })
    }
}


