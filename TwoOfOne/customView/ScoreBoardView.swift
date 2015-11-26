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
    
    init() {
        
        self.game = Game()
        self.moveCountLabel = UILabel()
        self.scoreLabel = UILabel()
        self.bonusTimeLabel = UILabel()
        
    }
    
    init(game:Game, moveCountLabel:UILabel, scoreLabel:UILabel, bonusTimeLabel:UILabel) {
        
        self.game = game
        self.moveCountLabel = moveCountLabel
        self.scoreLabel = scoreLabel
        self.bonusTimeLabel = bonusTimeLabel
        
        self.moveCountLabel.text = "999"
        
    }
    
    func updateScoreBoard(score:Int?, moveCounter:Int?) {
        if let myScore = score {
            self.scoreLabel.text = "\(myScore)"
        }
        if let myMoveCounter = moveCounter {
            self.moveCountLabel.text = "\(myMoveCounter)"
        }
        self.bonusTimeLabel.text = "---"
    }
}