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
    var progressViews:[JFScoreboardField:UIProgressView] = [:]
    
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
            case .TimeProgress, .TurnProgress, .ScoreProgress:
                if let progressView = scoreViews[scoreViewType] as? UIProgressView {
                    self.progressViews[scoreViewType] = progressView
                    progressView.alpha = 0
                    progressView.progress = 0
                } else {
                    print("error type mismatch")
                }
                break
            }
        }
    }
    
    func updateScoreBoardState(scoreViews:[JFScoreboardField:AnyObject]) {
        for scoreViewType in scoreViews.keys {
            switch(scoreViewType) {
            case .TimeProgress, .TurnProgress, .ScoreProgress:
                if let progressView = self.progressViews[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        progressView.tintColor = (value == 0) ? UIColor.greenColor() : UIColor.redColor()
                    }
                }
                break
            default:
                break
            }
        }
    }

    func updateScoreBoard(scoreViews:[JFScoreboardField:AnyObject]) {
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
                        label.text = "Score: \(value)"
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
                        label.text = "Turns: \(value)"
                    }
                }
                break
            case .Time:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = "Time: \(formatTime(value))"
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
            case .TimeProgress, .TurnProgress, .ScoreProgress:
                if let progressView = self.progressViews[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Float {
                        progressView.alpha = (value <= 0) ? 0 : 1
                        progressView.setProgress(value, animated: false)
                        //print("value:\(value)")
                    }
                }
                break
            }
        }
    }
}