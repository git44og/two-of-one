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
    (row:4, col:6, tile:150, corner:9, height:660),
    (row:5, col:8, tile:120, corner:7.5, height:660),
    (row:6, col:10, tile:100, corner:6, height:660),
]
let kConfigScale:Float = 0.025

class Game {
    
    var vc:UIViewController = UIViewController()
    var score:Int = 0
    var level:Int = 0
    var physics:Bool = true
    
    init(vc:UIViewController) {
        self.vc = vc
    }
    
    init() {
    }
    
    func cylinderRows() -> Int {
        return kTileConfig[self.level].row
    }
    
    func cylinderCols() -> Int {
        return kTileConfig[self.level].col
    }
    
    func cylinderTileWidth() -> Float {
        return kTileConfig[self.level].tile * kConfigScale
    }

    func cylinderHeight() -> Float {
        return kTileConfig[self.level].height * kConfigScale
    }
}