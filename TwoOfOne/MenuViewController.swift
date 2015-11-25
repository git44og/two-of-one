//
//  MenuViewController.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 25/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import UIKit

class MenuViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func onPlayPressed(sender: AnyObject) {
        
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("gameScreen") as! ViewController

        switch(sender.tag) {
        case 1:
            vc.game.level = 0
            break
        case 2:
            vc.game.level = 1
            break
        case 3:
            vc.game.level = 2
            break
        default:
            break
        }
        
        self.presentViewController(vc, animated: false) { () -> Void in
            vc.gamePlayIntro()
        }
    }
}