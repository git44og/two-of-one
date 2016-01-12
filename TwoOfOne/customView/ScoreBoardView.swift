//
//  ScoreBoardView.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 25/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit


enum JFScoreboardField:Int {
    case Score = 0
    case ScoreRef
    case ScoreProgress
    case Turn
    case TurnRef
    case TurnProgress
    case Time
    case TimeRef
    case TimeProgress
}

class ScoreBoardView {
    
    var game:Game
    var labels:[JFScoreboardField:UILabel] = [:]
    var progressViews:[JFScoreboardField:JFProgressView] = [:]
    var progressBlockViews:[JFScoreboardField:JFScoreBlockView] = [:]
    
    init() {
        
        self.game = Game()
    }
    
    init(game:Game, scoreViews:[JFScoreboardField:UIView]) {
        self.game = game
        for scoreViewType in scoreViews.keys {
            switch(scoreViewType) {
            case .Score, .ScoreRef, .Turn, .TurnRef, .Time, .TimeRef:
                if let label = scoreViews[scoreViewType] as? UILabel {
                    self.labels[scoreViewType] = label
                    label.text = ""
                } else {
                    print("error type mismatch")
                }
                break
            case .TimeProgress, .TurnProgress:
                if let progressView = scoreViews[scoreViewType] as? JFProgressView {
                    self.progressViews[scoreViewType] = progressView
                    progressView.alpha = 1
                    progressView.progress = 0
                } else {
                    print("error type mismatch")
                }
                break
            case .ScoreProgress:
                if let progressView = scoreViews[scoreViewType] as? JFScoreBlockView {
                    progressView.length = self.game.cylinderCols() * self.game.cylinderRows() / 2
                    self.progressBlockViews[scoreViewType] = progressView
                    progressView.alpha = 1
                } else {
                    print("error type mismatch")
                }
                break
            }
        }
    }
    
    func updateScoreBoard(scoreViews:[JFScoreboardField:Any]) {
        for scoreViewType in scoreViews.keys {
            switch(scoreViewType) {
            case .TurnRef:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = "Turns (par): \(value)"
                    }
                }
                break
            case .Score:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = "\(value)"
                    }
                }
                break
            case .ScoreRef:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = (value > 1) ? "Points for next pair: \(value) x 5" : "Points for next pair: 5"
                    }
                }
                break
            case .Turn:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = "\(value)"
                    }
                }
                break
            case .Time:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = "\(formatTime(value))"
                    }
                }
                break
            case .TimeRef:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = "Time (par): \(formatTime(value))"
                    }
                }
                break
            case .TimeProgress, .TurnProgress:
                if let progressView = self.progressViews[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Float {
                        //progressView.alpha = (value <= 0) ? 0 : 1
                        progressView.setProgress(value, animated: false)
                        //print("value:\(value)")
                    }
                }
                break
            case .ScoreProgress:
                if let progressView = self.progressBlockViews[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? JFProgressBlockState {
                        progressView.pair(value.index, bonus: value.bonus)
                        //print("value:\(value)")
                    }
                }
                break
            }
        }
    }
}