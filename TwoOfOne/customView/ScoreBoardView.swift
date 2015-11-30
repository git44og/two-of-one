//
//  ScoreBoardView.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 25/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit

class ScoreBoardView {
    
    var game:Game
    var moveCountLabel:UILabel
    var scoreLabel:UILabel
    var bonusTimeLabel:UILabel
    var bonusProgressView:UIProgressView
    
    init() {
        
        self.game = Game()
        self.moveCountLabel = UILabel()
        self.scoreLabel = UILabel()
        self.bonusTimeLabel = UILabel()
        self.bonusProgressView = UIProgressView()
        
    }
    
    init(game:Game, moveCountLabel:UILabel, scoreLabel:UILabel, bonusTimeLabel:UILabel, bonusProgressView:UIProgressView) {
        
        self.game = game
        self.moveCountLabel = moveCountLabel
        self.scoreLabel = scoreLabel
        self.bonusTimeLabel = bonusTimeLabel
        self.bonusProgressView = bonusProgressView
        
        self.moveCountLabel.text = ""
        self.scoreLabel.text = ""
        self.bonusTimeLabel.text = ""
        self.bonusProgressView.hidden = true
    }
    
    func updateScoreBoard(bonusCounter:Float) {
        self.bonusProgressView.hidden = (bonusCounter <= 0)
        //self.bonusTimeLabel.text = (bonusCounter == 0) ? "" : String(NSString(format: "%.2f%", bonusCounter))
        self.bonusProgressView.setProgress(bonusCounter, animated: false)
    }
    
    func updateScoreBoard(score:Int?, moveCounter:Int?, bonusLabel:Int?) {
        if let myScore = score {
            self.scoreLabel.text = "\(myScore)"
        }
        if let myMoveCounter = moveCounter {
            self.moveCountLabel.text = "\(myMoveCounter)"
        }
        if let myBonusLabel = bonusLabel {
            if(bonusLabel > 1) {
                self.bonusTimeLabel.text = "\(myBonusLabel)x"
            } else {
                self.bonusTimeLabel.text = ""
            }
        }
    }
}