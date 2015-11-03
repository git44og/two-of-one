//
//  JFGraphUtils.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 02/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import SceneKit


func bezierPathRoundedRectangle(size:CGSize, stroke:CGFloat, cornerRadius:CGFloat) -> UIBezierPath {
    return bezierPathRoundedRectangle(CGRect(origin: CGPoint(x: size.width / -2, y: size.height / -2), size: size), stroke: stroke, cornerRadius: cornerRadius)
}

func bezierPathRoundedRectangle(rect:CGRect, stroke:CGFloat, cornerRadius:CGFloat) -> UIBezierPath {
    if((rect.width < (cornerRadius * 2)) || (rect.height < (cornerRadius * 2))) {
        return UIBezierPath()
    }
    
    let innerCornerRadius = cornerRadius - stroke
    let innerRect = CGRect(x: rect.origin.x + stroke, y: rect.origin.y + stroke, width: rect.size.width - (stroke * 2), height: rect.size.height - (stroke * 2))
    
    let path = UIBezierPath()
    path.flatness = stroke / 10
    path.moveToPoint(
        CGPoint(
            x: rect.origin.x + cornerRadius,
            y: rect.origin.y))
    // top
    path.addLineToPoint(
        CGPoint(
            x: rect.origin.x + rect.size.width - cornerRadius,
            y: rect.origin.y))
    // top right
    path.addArcWithCenter(
        CGPoint(
            x: rect.origin.x + rect.size.width - cornerRadius,
            y: rect.origin.y + cornerRadius),
        radius: cornerRadius,
        startAngle: CGFloat(M_PI) * -0.5,
        endAngle: 0,
        clockwise: true)
    // right
    path.addLineToPoint(
        CGPoint(
            x: rect.origin.x + rect.size.width,
            y: rect.origin.y + rect.size.height - cornerRadius))
    // bottom right
    path.addArcWithCenter(
        CGPoint(
            x: rect.origin.x + rect.size.width - cornerRadius,
            y: rect.origin.y + rect.size.height - cornerRadius),
        radius: cornerRadius,
        startAngle: 0,
        endAngle: CGFloat(M_PI) * 0.5,
        clockwise: true)
    // bottom
    path.addLineToPoint(
        CGPoint(
            x: rect.origin.x + cornerRadius,
            y: rect.origin.y + rect.size.height))
    // bottom left
    path.addArcWithCenter(
        CGPoint(
            x: rect.origin.x + cornerRadius,
            y: rect.origin.y + rect.size.height - cornerRadius),
        radius: cornerRadius,
        startAngle: CGFloat(M_PI) * 0.5,
        endAngle: CGFloat(M_PI) * 1,
        clockwise: true)
    // left
    path.addLineToPoint(
        CGPoint(
            x: rect.origin.x,
            y: rect.origin.y + cornerRadius))
    // top left
    path.addArcWithCenter(
        CGPoint(
            x: rect.origin.x + cornerRadius,
            y: rect.origin.y + cornerRadius),
        radius: cornerRadius,
        startAngle: CGFloat(M_PI) * 1,
        endAngle: CGFloat(M_PI) * 1.5,
        clockwise: true)
    
    
    // inner path
    path.moveToPoint(
        CGPoint(
            x: innerRect.origin.x + innerCornerRadius,
            y: innerRect.origin.y))
    // top
    path.addLineToPoint(
        CGPoint(
            x: innerRect.origin.x + innerRect.size.width - innerCornerRadius,
            y: innerRect.origin.y))
    // top right
    path.addArcWithCenter(
        CGPoint(
            x: innerRect.origin.x + innerRect.size.width - innerCornerRadius,
            y: innerRect.origin.y + innerCornerRadius),
        radius: innerCornerRadius,
        startAngle: CGFloat(M_PI) * -0.5,
        endAngle: 0,
        clockwise: true)
    // right
    path.addLineToPoint(
        CGPoint(
            x: innerRect.origin.x + innerRect.size.width,
            y: innerRect.origin.y + innerRect.size.height - innerCornerRadius))
    // bottom right
    path.addArcWithCenter(
        CGPoint(
            x: innerRect.origin.x + innerRect.size.width - innerCornerRadius,
            y: innerRect.origin.y + innerRect.size.height - innerCornerRadius),
        radius: innerCornerRadius,
        startAngle: 0,
        endAngle: CGFloat(M_PI) * 0.5,
        clockwise: true)
    // bottom
    path.addLineToPoint(
        CGPoint(
            x: innerRect.origin.x + innerCornerRadius,
            y: innerRect.origin.y + innerRect.size.height))
    // bottom left
    path.addArcWithCenter(
        CGPoint(
            x: innerRect.origin.x + innerCornerRadius,
            y: innerRect.origin.y + innerRect.size.height - innerCornerRadius),
        radius: innerCornerRadius,
        startAngle: CGFloat(M_PI) * 0.5,
        endAngle: CGFloat(M_PI) * 1,
        clockwise: true)
    // left
    path.addLineToPoint(
        CGPoint(
            x: innerRect.origin.x,
            y: innerRect.origin.y + innerCornerRadius))
    // top left
    path.addArcWithCenter(
        CGPoint(
            x: innerRect.origin.x + innerCornerRadius,
            y: innerRect.origin.y + innerCornerRadius),
        radius: innerCornerRadius,
        startAngle: CGFloat(M_PI) * 1,
        endAngle: CGFloat(M_PI) * 1.5,
        clockwise: true)

    //path.closePath()
    return path
}