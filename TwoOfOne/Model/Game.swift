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
let kUpdateInterval:NSTimeInterval = 0.3

enum JFMoveType:Int {
    case flipTile = 0
    case findPair = 1
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
        case .findPair:
            self.score += 5

            self.bonusTimer = NSTimer.scheduledTimerWithTimeInterval(self.bonusTimerInterval(), target: self, selector: "bonusTimerFire:", userInfo: nil, repeats: false)
            self.bonusUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(kUpdateInterval, target: self, selector: Selector("bonusUpdateTimerFire:"), userInfo: nil, repeats: true)
            break
        }
        self.updateScoreBoard()
    }
    
    //MARK: bonus handling
    func bonusTimerInterval() -> NSTimeInterval {
        return 3
    }
    
    // @objc prefaces method as objective-c conform
    @objc func bonusTimerFire(timer:NSTimer) {
        self.bonusTimer.invalidate()
        self.bonusUpdateTimer.invalidate()
    }
    
    @objc func bonusUpdateTimerFire(timer:NSTimer) {
        if(self.bonusTimer.valid) {
            print("\(self.bonusTimer.fireDate.timeIntervalSinceNow)")
        } else {
            self.bonusUpdateTimer.invalidate()
        }
    }
    
    //MARK: handling scores
    func updateScoreBoard() {
        if let sbv = self.scoreBoard {
            sbv.updateScoreBoard(self.score, moveCounter: self.moveCounter)
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