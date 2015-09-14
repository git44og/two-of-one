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

func execDelay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func shuffleList<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
    let c = count(list)
    for i in 0..<(c - 1) {
        let j = Int(arc4random_uniform(UInt32(c - i))) + i
        swap(&list[i], &list[j])
    }
    return list
}
