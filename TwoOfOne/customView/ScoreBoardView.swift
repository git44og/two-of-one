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
            case .TimeProgress, .TurnProgress:
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
    
    func updateScoreBoard(scoreViews:[JFScoreboardField:AnyObject]) {
        for scoreViewType in scoreViews.keys {
            switch(scoreViewType) {
            case .Score, .ScoreRef, .Turn, .TurnRef:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = "\(value)"
                    }
                }
                break
            case .Time:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        label.text = (value > 1) ? "\(value)x" : ""
                    }
                }
                break
            case .TimeRef:
                if let label = self.labels[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Int {
                        let hour = value / 3600
                        let minute = (value / 60) % 60
                        let second = value % 60
                        var hourStr = ""
                        var minuteStr = ""
                        var secondStr = ""
                        if(hour > 0) {
                            hourStr = (hour > 0) ? "\(hour):" : ""
                            minuteStr = (minute > 9) ? "\(minute):" : ((minute > 0) ? "0\(minute):" : "00:")
                            secondStr = (second > 9) ? "\(second)" : ((second > 0) ? "0\(second)" : "00")
                        } else {
                            minuteStr = (minute > 0) ? "\(minute):" : "0:"
                            secondStr = (second > 9) ? "\(second)" : ((second > 0) ? "0\(second)" : "00")
                        }
                        label.text = "\(hourStr)\(minuteStr)\(secondStr)"
                    }
                }
                break
            case .TimeProgress, .TurnProgress:
                if let progressView = self.progressViews[scoreViewType] {
                    if let value = scoreViews[scoreViewType] as? Float {
                        progressView.alpha = (value <= 0) ? 0 : 1
                        progressView.setProgress(value, animated: false)
                        print("value:\(value)")
                    }
                }
                break
            }
        }
    }
}