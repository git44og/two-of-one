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
}


class Game {
    
    var vc:UIViewController = UIViewController()
    var score:Int = 0
    var moveCounter:Int = 0
    var bonusLevel:Int = 0
    var bonusTimer:NSTimer = NSTimer()
    var bonusUpdateTimer:NSTimer = NSTimer()
    var level:Int = 0
    var physics:Bool = true
    var scoreBoard:ScoreBoardView? {
        didSet {
            self.updateScoreBoard()
        }
    }
    
    init(vc:UIViewController) {
        self.vc = vc
        self.updateScoreBoard()
    }
    
    init() {
    }
    
    //MARK: scoring
    func event(mvoeType:JFMoveType) {
        switch(mvoeType) {
        case .flipTile:
            self.moveCounter++
            break
            
        case .flipBackTile:
            self.bonusLevel = 0
            self.moveCounter++
            self.cancelBonusTimer()
            
        case .findPair:
            self.score += self.scoreOnBonus()
            self.bonusLevel++
            self.cancelBonusTimer()
            self.startBonusTimer()
            break
            
        case .findNoPair:
            self.bonusLevel = 0
            self.cancelBonusTimer()
            break
        }
        self.updateScoreBoard()
    }
    
    //MARK: bonus handling
    func scoreOnBonus() -> Int {
        print("score \(kBaseScore) at level \(self.bonusLevel)")
        return kBaseScore * (self.bonusLevel + 1)
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
    
    func startBonusTimer() {
        print("start bonus timer at level \(self.bonusLevel) with time \(self.bonusTimerInterval())")
        self.bonusTimer = NSTimer.scheduledTimerWithTimeInterval(self.bonusTimerInterval(), target: self, selector: "bonusTimerFire:", userInfo: nil, repeats: false)
        self.bonusUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(kUpdateInterval, target: self, selector: Selector("bonusUpdateTimerFire:"), userInfo: nil, repeats: true)
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard(0)
        }
    }
    
    func cancelBonusTimer() {
        self.bonusTimer.invalidate()
        self.bonusUpdateTimer.invalidate()
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard(0)
        }
    }
    
    // @objc prefaces method as objective-c conform
    @objc func bonusTimerFire(timer:NSTimer) {
        self.bonusLevel = 0
        self.updateScoreBoard()
        self.cancelBonusTimer()
    }
    
    @objc func bonusUpdateTimerFire(timer:NSTimer) {
        if(self.bonusTimer.valid) {
            let progressLeft = Float(self.bonusTimer.fireDate.timeIntervalSinceNow / self.bonusTimerInterval())
            //print("\(progressLeft)")
            if let sbv = self.scoreBoard {
                sbv.updateScoreBoard(progressLeft)
            }
        } else {
            self.bonusUpdateTimer.invalidate()
            if let sbv = self.scoreBoard {
                sbv.updateScoreBoard(0)
            }
        }
    }
    
    //MARK: handling scores
    func updateScoreBoard() {
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard(self.score, moveCounter: self.moveCounter, bonusLabel: self.bonusLevel)
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