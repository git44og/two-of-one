//
//  JFProgressView.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 11/01/16.
//  Copyright © 2016 Jens. All rights reserved.
//

import Foundation
import UIKit

enum JFProgressViewType:Int {
    case Bonus = 0
    case Score
}

let kProgressViewSizeSeparator:CGFloat = 1
let kProgressViewGreenColor = UIColor(red: 171/255, green: 202/255, blue: 65/255, alpha: 1.0)
let kProgressViewRedColor = UIColor(red: 220/255, green: 65/255, blue: 136/255, alpha: 1.0)
let kProgressViewSeparatorColor = UIColor.whiteColor()

let kScoreBlockViewSeparator:CGFloat = 1
let kScoreBlockViewBonusColor = UIColor(red: 7/255, green: 152/255, blue: 153/255, alpha: 1.0)
let kScoreBlockViewNormalColor = UIColor(red: 171/255, green: 202/255, blue: 65/255, alpha: 1.0)

class JFProgressView: UIView {
    
    var parProgress:Float = 2 / 3
    var progress:Float = 0 {
        didSet {
            if(progress > 1) {
                progress = 1
            } else if(progress < 0) {
                progress = 0
            }
            
            UIView.animateWithDuration(0.3,
                delay: 0,
                options: UIViewAnimationOptions.CurveLinear,
                animations: { () -> Void in
                    self.progressBar[0]!.progress = max(self.parProgress - self.progress, 0) / self.parProgress
                    self.progressBar[1]!.progress = max(self.progress - self.parProgress, 0) / (1 - self.parProgress)
                },
                completion:nil)
        }
    }
    var progressBar:[Int:JFProgressViewBar] = [:]
    
    init(frame:CGRect, type:JFProgressViewType) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor()
        
        let locationSepartor = round(self.frame.size.width * CGFloat(self.parProgress))
        let frameBarLeft = CGRect(
            x: 0,
            y: 0,
            width: locationSepartor,
            height: self.frame.size.height)
        let frameSeparator = CGRect(
            x: locationSepartor,
            y: 0,
            width: kProgressViewSizeSeparator,
            height: self.frame.size.height)
        let frameBarRight = CGRect(
            x: locationSepartor + kProgressViewSizeSeparator,
            y: 0,
            width: self.frame.size.width - (locationSepartor + kProgressViewSizeSeparator),
            height: self.frame.size.height)
        
        let barLeft = JFProgressViewBar(frame: frameBarLeft, barColor:kProgressViewGreenColor, orientation:JFProgressBarOrientation.Right)
        self.addSubview(barLeft)
        self.progressBar[0] = barLeft
        
        let barSeparator = UIView(frame: frameSeparator)
        barSeparator.backgroundColor = kProgressViewSeparatorColor
        self.addSubview(barSeparator)
        
        let barRight = JFProgressViewBar(frame: frameBarRight, barColor:kProgressViewRedColor, orientation:JFProgressBarOrientation.Left)
        self.progressBar[1] = barRight
        self.addSubview(barRight)
    }
    
    func setProgress(progress:Float, animated:Bool) {
        self.progress = progress
    }
}


enum JFProgressBarOrientation:Int {
    case Left = 0
    case Right
}


class JFProgressViewBar: UIView {
    
    var progress:Float = 0 {
        didSet {
            self.updateViews()
        }
    }
    var orientation:JFProgressBarOrientation = .Left
    var bar:UIView
    
    init(frame: CGRect, barColor:UIColor, orientation:JFProgressBarOrientation) {
        
        self.orientation = orientation
        switch(orientation) {
        case .Left:
            self.bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: frame.size.height))
            break
        case .Right:
            self.bar = UIView(frame: CGRect(x: frame.size.width, y: 0, width: 0, height: frame.size.height))
            break
        }
        
        super.init(frame: frame)
        
        self.bar.backgroundColor = barColor
        self.addSubview(self.bar)
        self.backgroundColor = UIColor(white: 0, alpha: 0.9)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // update the actual progress bar - method should be called whenever progress has changed
    func updateViews() {
        
        switch(self.orientation) {
        case .Left:
            self.bar.frame = CGRect(x: 0, y: 0, width: self.frame.size.width * CGFloat(self.progress), height: self.frame.size.height)
            break
        case .Right:
            self.bar.frame = CGRect(x: self.frame.size.width * (1 - CGFloat(self.progress)), y: 0, width: self.frame.size.width * CGFloat(self.progress), height: self.frame.size.height)
            break
        }

    }
}



class JFScoreBlockView: UIView {
    
    var length:Int = 30 {
        didSet {
            setBlockViews()
        }
    }
    var blockViews:[Int:UIView] = [:]
    
    init(frame:CGRect, type:JFProgressViewType) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor()
    }
    
    func setBlockViews() {
        
        for subView in self.subviews {
            subView.removeFromSuperview()
        }
        self.blockViews = [:]
        
        let blockLength = (self.frame.size.width - (CGFloat(length - 1) * kScoreBlockViewSeparator)) / CGFloat(length)
        
        for index in 0...(self.length - 1) {
            let offset = CGFloat(index) * (blockLength + kScoreBlockViewSeparator)
            let blockView = UIView(frame: CGRect(x: offset, y: 0, width: blockLength, height: self.frame.size.height))
            blockView.backgroundColor = UIColor.clearColor()
            self.blockViews[index] = blockView
            self.addSubview(blockView)
        }
    }
    
    func pair(pairIndex:Int, bonus:Bool) {
        if let blockView = self.blockViews[pairIndex] {
            blockView.backgroundColor = bonus ? kScoreBlockViewBonusColor : kScoreBlockViewNormalColor
        }
    }
}
