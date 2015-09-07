//
//  JFUtils.swift
//  TwoOfOne
//
//  Created by Jens on 7/09/2015.
//  Copyright (c) 2015 Jens. All rights reserved.
//

import Foundation

func JFrand(count: Int) -> Int {
    return Int(arc4random_uniform(UInt32(count)))
}
