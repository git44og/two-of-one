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
let kBaseScore:Int = 5

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


class Game {
    var vc:UIViewController = UIViewController()
    var parTurns:Int = 10
    var parTime:NSTimeInterval = 20
    var startDate:NSDate = NSDate()
    var score:Int = 0
    var turn:Int = 0
    var bonusLevel:Int = 0
    var bonusTimer:NSTimer = NSTimer()
    var bonusUpdateTimer:NSTimer = NSTimer()
    var level:Int = 0
    var physics:Bool = true
    var enableBackOfTiles:Bool = false
    var scoreBoard:ScoreBoardView? {
        didSet {
            self.updateScoreBoard()
        }
    }
    // debug
    var debugPairs:Bool = false
    
    init(vc:UIViewController) {
        self.vc = vc
        self.updateScoreBoard()
    }
    
    init() {
    }
    
    //MARK: scoring
    func event(mvoeType:JFMoveType) {
        switch(mvoeType) {
        case .InitGame:
            if let sbv = self.scoreBoard {
                sbv.updateScoreBoard([JFScoreboardField.TurnRef : self.parTurns, JFScoreboardField.TimeRef : self.parTime, JFScoreboardField.Time : 0])
            }
            
            break
        case .StartGame:
            self.startDate = NSDate()
            self.bonusLevel = 1
            self.score = 0
            self.turn = 0
            self.startUpdateTimer()

            break
        case .FinishGame:
            self.cancelBonusTimer()
            break
        case .flipTile:
            self.turn++
            break
            
        case .flipBackTile:
            self.turn++
            self.event(.BonusInvalid)
            
        case .findPair:
            self.score += self.scoreOnBonus()
            self.bonusLevel++
            //self.cancelBonusTimer()
            //self.startBonusTimer()
            break
            
        case .findNoPair:
            self.event(.BonusInvalid)
            break
        case .BonusInvalid:
            self.bonusLevel = 1
            self.updateScoreBoard()
            //self.cancelBonusTimer()
        }
        self.updateScoreBoard()
    }
    
    func totalScore() -> Int {
        return self.score - self.turn
    }
    
    //MARK: bonus handling
    func scoreOnBonus() -> Int {
        print("score \(kBaseScore) at level \(self.bonusLevel)")
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
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard([JFScoreboardField.TimeProgress : 0])
        }
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
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard([JFScoreboardField.Time:Int(timeSince)])
        }
    }
    
    //MARK: handling scores
    func updateScoreBoard() {
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard([.Score:self.score, .Turn:self.turn, .ScoreRef:self.bonusLevel])
        }
    }
    
    //MARK: appearance
    func cylinderRows() -> Int {
        return kTileConfig[self.level].row
    }
    
    func cylinderCols() -> Int {
        return kTileConfig[self.level].col
    }
    
    func cylinderTileWidth() -> Float {
        return kTileConfig[self.level].tile
    }

    func cylinderHeight() -> Float {
        return kTileConfig[self.level].height
    }
}