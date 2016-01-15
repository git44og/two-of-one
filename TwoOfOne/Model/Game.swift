//
//  Game.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 16/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit

// game modes
let kTileConfig:[(row:Int, col:Int, tile:Float, corner:Float, height:Float)] =
[
    (row:4, col:6, tile:150 * kConfigScale, corner:9, height:660 * kConfigScale),
    (row:5, col:8, tile:120 * kConfigScale, corner:7.5, height:660 * kConfigScale),
    (row:6, col:10, tile:100 * kConfigScale, corner:6, height:660 * kConfigScale),
]
let kUpdateInterval:NSTimeInterval = 0.1
let kBaseScore:Int = 10
let kTurnBonusRatio:Float = 3 // bonus for turns can be x-times the absolute value of the min bonus. ie if minBonus = -100, max bonus is +100 * kTurnBonusRatio
let kTimeBonusRatio:Float = 3

enum JFGameLevel:Int {
    case Beginner = 0
    case Medium = 1
    case Expert = 2
}

enum JFMoveType:Int {
    case flipTile = 0
    case flipBackTile
    case findPair
    case findNoPair
    case InitGame
    case StartGame
    case FinishGame
    case BonusInvalid
}

struct JFProgressBlockState {
    var index: Int
    var bonus: Bool
}


class Game {
    var vc:UIViewController = UIViewController()
    var parTurns:Int = 40
    var parTime:NSTimeInterval = 120
    var startDate:NSDate = NSDate()
    var score:Int = 0
    var turn:Int = 0
    var time:Int = 0
    var bonusLevel:Int = 0
    var bonusTimer:NSTimer = NSTimer()
    var bonusUpdateTimer:NSTimer = NSTimer()
    var foundPairs:Int = 0
    var level:JFGameLevel = .Beginner
    var physics:Bool = true
    var enableBackOfTiles:Bool = false
    var scoreBoard:ScoreBoardView? {
        didSet {
            self.updateScoreBoard()
        }
    }
    // debug
    var debugPairs:Bool = false
    
    init(vc:ViewController) {
        self.vc = vc
        self.updateScoreBoard()
    }
    
    init() {
    }
    
    //MARK: scoring
    func event(mvoeType:JFMoveType, info:Any? = nil) {
        switch(mvoeType) {
        case .InitGame:
            self.bonusLevel = 1
            self.score = 0
            self.turn = 0
            self.foundPairs = 0
            self.updateScoreBoard()
            
            break
        case .StartGame:
            self.startDate = NSDate()
            self.bonusLevel = 1
            self.score = 0
            self.turn = 0
            self.foundPairs = 0
            self.startUpdateTimer()
            self.updateScoreBoard()

            break
        case .FinishGame:
            self.time = Int(-self.startDate.timeIntervalSinceNow)
            self.cancelBonusTimer()
            self.updateScoreBoard()
            break
        case .flipTile:
            //self.turn++
            //self.updateScoreBoardTurns()
            break
            
        case .flipBackTile:
            //self.turn++
            self.event(.BonusInvalid)
            //self.updateScoreBoardTurns()
            
        case .findPair:
            self.score += self.scoreOnBonus()
            self.turn++
            
            if let pairingTiles = info as? [JFTileNode] {
                pairingTiles[0].scoredWithTile = self.scoreOnBonus()
                pairingTiles[1].scoredWithTile = self.scoreOnBonus()
            }
            
            self.updateScoreBoardTurns()
            if let sbv = self.scoreBoard {
                sbv.updateScoreBoard([JFScoreboardField.ScoreProgress:JFProgressBlockState(index: self.foundPairs, bonus: (self.bonusLevel > 1))])
            }

            self.foundPairs++
            self.bonusLevel++
            
            if let myVc = vc as? ViewController {
                if(myVc.cylinderNode.solved()) {
                    myVc.gameSolved()
                }
            }

            break
            
        case .findNoPair:
            self.turn++
            self.updateScoreBoardTurns()
            self.event(.BonusInvalid)
            break
        case .BonusInvalid:
            self.bonusLevel = 1
            self.updateScoreBoard()
        }
        
        // will be 2/3 at parTime
        // < 2/3 linear, > 2/3 curved
        var turnProgress:Float = 1
        if(self.turn <= self.parTurns) {
            turnProgress = (1 / Float(self.parTurns)) * (2 / 3) * Float(self.turn)
            //print("flat: \(turnProgress)")
        } else {
            turnProgress = 1 - ((Float(self.parTurns) * 1 / 3) / Float(self.turn))
            //print("curve: \(turnProgress)")
        }
        //print("par:\(self.parTurns) turn:\(self.turn) prog \(turnProgress)")
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard([
                JFScoreboardField.TurnProgress:turnProgress])
        }
    }
    
    func turnBonus() -> Int {
        let offset = Float(self.parTurns) / kTurnBonusRatio
        let minBonusFactor = (Float(self.cylinderCols() * self.cylinderRows()) / 2) * Float(kBaseScore)
        let bonusFactor = (1 / ((Float(self.turn) + offset) / (Float(self.parTurns) + offset))) - 1
        let bonus = bonusFactor * minBonusFactor
        return Int(bonus)
    }
    
    func timeBonus() -> Int {
        let offset = Float(self.parTime) / kTimeBonusRatio
        let minBonusFactor = (Float(self.cylinderCols() * self.cylinderRows()) / 2) * Float(kBaseScore)
        let bonusFactor = (1 / ((Float(self.time) + offset) / (Float(self.parTime) + offset))) - 1
        let bonus = bonusFactor * minBonusFactor
        return Int(bonus)
    }
    
    func totalScore() -> Int {
        return self.score + self.timeBonus() + self.turnBonus()
    }
    
    //MARK: bonus handling
    func scoreOnBonus() -> Int {
        //print("score \(kBaseScore) at level \(self.bonusLevel)")
        return kBaseScore * (self.bonusLevel)
    }
    
    func bonusTimerInterval() -> NSTimeInterval {
        switch(bonusLevel) {
        case 0:
            return 20
        case 1:
            return 15
        case 2:
            return 12
        case 3:
            return 10
        case 4:
            return 8
        case 5:
            return 6
        case 6:
            return 5
        default:
            return 4
        }
    }
    
    /*
    func startBonusTimer() {
        print("start bonus timer at level \(self.bonusLevel) with time \(self.bonusTimerInterval())")
        self.bonusTimer = NSTimer.scheduledTimerWithTimeInterval(self.bonusTimerInterval(), target: self, selector: "bonusTimerFire:", userInfo: nil, repeats: false)
        self.bonusUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(kUpdateInterval, target: self, selector: Selector("bonusUpdateTimerFire:"), userInfo: nil, repeats: true)
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard([JFScoreboardField.TimeProgress : 0])
        }
    }
    */
    
    func startUpdateTimer() {
        self.bonusUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(kUpdateInterval, target: self, selector: Selector("updateTimerFire:"), userInfo: nil, repeats: true)
        //self.bonusUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(kUpdateInterval, target: self, selector: Selector("bonusUpdateTimerFire:"), userInfo: nil, repeats: true)
    }
    
    func cancelBonusTimer() {
        self.bonusTimer.invalidate()
        self.bonusUpdateTimer.invalidate()
    }
    
    // @objc prefaces method as objective-c conform
    @objc func bonusTimerFire(timer:NSTimer) {
        self.event(.BonusInvalid)
    }
    /*
    @objc func bonusUpdateTimerFire(timer:NSTimer) {
        if(self.bonusTimer.valid) {
            let progressLeft = Float(self.bonusTimer.fireDate.timeIntervalSinceNow / self.bonusTimerInterval())
            //print("\(progressLeft)")
            if let sbv = self.scoreBoard {
                sbv.updateScoreBoard([JFScoreboardField.TimeProgress : progressLeft])
            }
        } else {
            self.bonusUpdateTimer.invalidate()
            if let sbv = self.scoreBoard {
                sbv.updateScoreBoard([JFScoreboardField.TimeProgress : 0])
            }
        }
    }
    */
    @objc func updateTimerFire(timer:NSTimer) {
        let timeSince = -self.startDate.timeIntervalSinceNow
        // will be 2/3 at parTime
        // < 2/3 linear, > 2/3 curved
        var timeProgress:Float = 1
        if(timeSince <= self.parTime) {
            timeProgress = Float((1 / self.parTime) * (2 / 3) * timeSince)
            //print("flat: \(timeProgress)")
        } else {
            timeProgress = Float(1 - ((self.parTime * 1 / 3) / timeSince))
            //print("curve: \(timeProgress)")
        }
        //let timeProgress:Float = Float(1 - ((self.parTime / (timeSince + self.parTime)) * 2/3))
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard([
                JFScoreboardField.Time:Int(timeSince),
                JFScoreboardField.TimeProgress:timeProgress])
        }
    }
    
    //MARK: handling scores
    func updateScoreBoard() {
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard([.Score:self.score, .Turn:self.turn, .ScoreRef:self.bonusLevel])
        }
    }
    
    func updateScoreBoardTurns() {
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard([.Turn:self.turn])
        }
    }
    
    //MARK: appearance
    func cylinderRows() -> Int {
        return self.levelConfig().row
    }
    
    func cylinderCols() -> Int {
        return self.levelConfig().col
    }
    
    func cylinderTileWidth() -> Float {
        return self.levelConfig().tile
    }

    func cylinderHeight() -> Float {
        return self.levelConfig().height
    }
    
    func levelConfig() -> (row:Int, col:Int, tile:Float, corner:Float, height:Float) {
        switch(self.level) {
        case .Beginner:
            return kTileConfig[0]
        case .Medium:
            return kTileConfig[1]
        case .Expert:
            return kTileConfig[2]
        }
    }
}