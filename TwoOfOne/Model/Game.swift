//
//  Game.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 16/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit

class Game {
    
    var score:Int = 0
    var vc:UIViewController = UIViewController()

    init(vc:UIViewController) {
        self.vc = vc
    }
    
    init() {
    }
}