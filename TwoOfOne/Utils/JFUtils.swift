//
//  JFUtils.swift
//  TwoOfOne
//
//  Created by Jens on 7/09/2015.
//  Copyright (c) 2015 Jens. All rights reserved.
//

import Foundation
import SceneKit

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
    let c = list.count
    for i in 0..<(c - 1) {
        let j = Int(arc4random_uniform(UInt32(c - i))) + i
        if(i != j) {
            swap(&list[i], &list[j])
        }
    }
    return list
}

// reduces angle to bounds ]-pi,+pi[
func normalizeAngle(angle:Float) -> Float {
    var normAngle = angle
    while(normAngle > Float(M_PI)) {
        normAngle -= Float(M_PI * 2)
    }
    while(normAngle < -Float(M_PI)) {
        normAngle += Float(M_PI * 2)
    }
    return normAngle
}

// returns y rotation with positive y vector
func normalizeRotationY(rotation:SCNVector4) -> Float {
    if(rotation.y > 0.5) {
        return rotation.w
    } else if(rotation.y < -0.5) {
        return -rotation.w
    }
    return 0
}

// limits angle to top / bottom
// slows angleSpeed towards limits
func easeAngle(angle:Double, maxTop:Double, maxBottom:Double) -> Double {
    if((angle >= 0) && (angle < maxTop)) {
        return sin((angle / maxTop) * M_PI_2) * maxTop
    } else if((angle > maxBottom) && (angle < 0)) {
        return sin((angle / maxBottom) * M_PI_2) * maxBottom
    } else if(angle >= maxTop) {
        return maxTop
    } else if(angle <= maxBottom) {
        return maxBottom
    }
    return angle
}

// MARK: Math

func sign(number:Float) -> Float {
    return (number < 0) ? -1 : +1
}