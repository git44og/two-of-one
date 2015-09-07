//
//  ViewController.swift
//  TwoOfOne
//
//  Created by Jens on 2/09/2015.
//  Copyright (c) 2015 Jens. All rights reserved.
//

import UIKit
import SceneKit



class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: SCNView!
    // Geometry
    var geometryNode: JFSCNNode = JFSCNNode()
    
    // Gestures
    var currentAngle: Float = 0.0
    var currentPos: Float = 0.0
    //var prevDate: Int64 = 0
    //var prevTranslation: CGPoint = CGPoint()
    //var currDate: Int64 = 0
    //var currTranslation: CGPoint = CGPoint()
    var sceneSizeFactor:Float = 1.0
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        let scene = SCNScene()
        
        
        // light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor(white: 0.67, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLightTypeOmni
        omniLightNode.light!.color = UIColor(white: 0.75, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(0, 50, 50)
        scene.rootNode.addChildNode(omniLightNode)
        
        // camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        //cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.yFov = 20
        cameraNode.position = SCNVector3Make(0, 0, 21)
        scene.rootNode.addChildNode(cameraNode)
        
        self.sceneSizeFactor = (Float)(sceneView.frame.size.height / sceneView.frame.size.width * 1.35)
        
        // group
        let groupNode = JFSCNNode()
        //groupNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI / -4))
        scene.rootNode.addChildNode(groupNode)
        groupNode.generateTileNodes()
        groupNode.adjustTransparency()
        
        // box
        let boxGeometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)
        let boxNode = SCNNode(geometry: boxGeometry)
        //scene.rootNode.addChildNode(boxNode)
        
        geometryNode = groupNode
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "panGesture:")
        sceneView.addGestureRecognizer(panRecognizer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapGesture:")
        sceneView.addGestureRecognizer(tapRecognizer)
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Style
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: Transition
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        sceneView.stop(nil)
        sceneView.play(nil)
    }
    
    //MARK: Gesture
    func tapGesture(sender: UITapGestureRecognizer) {
        let translation = sender.locationInView(sender.view!)
        if let objs = self.sceneView.hitTest(translation, options: nil) {
            if(objs.count > 0) {
                let nearestObject = objs[0] as! SCNHitTestResult
                let hitNode = nearestObject.node as! JFTileNode
                hitNode.flip()
//                self.nodeActive(hitNode, active: true)
//                println("tap x:\(translation.x) y:\(translation.y) hit:\(hitNode.name)")
            }
        }
    }
    
    func panGesture(sender: UIPanGestureRecognizer) {
        
        let translation = sender.translationInView(sender.view!)
        
        var newAngle = (Float)(translation.x) * self.sceneSizeFactor * (Float)(M_PI) / 180.0
        newAngle += currentAngle
        let rotateMatrix = SCNMatrix4MakeRotation(newAngle, 0, 1, 0)
        
        var newPos = (Float)(translation.x) * self.sceneSizeFactor * (Float)(M_PI) / 100.0
        newPos += currentPos
        let moveMatrix = SCNMatrix4MakeTranslation(newPos, 0, 0)
        geometryNode.transform = SCNMatrix4Mult(rotateMatrix, moveMatrix)
        
        var nowDouble = NSDate().timeIntervalSince1970
        println("tx:\(translation.x) ty:\(translation.y) time:\(Int64(nowDouble*1000))")
        if(sender.state == UIGestureRecognizerState.Ended) {
            
            // missing degrees
            //let tmpPi = (newAngle / Float(M_PI)) // -> full circle = 2
            let angleIntPerQuarter = (newAngle / Float(M_PI)) * (Float(tileNum) / 2) // 45deg == 1 | 90deg == 2
            let missingAngleIntPerQuarter = round(angleIntPerQuarter) - angleIntPerQuarter
            //let misPi = misInt / 4
            let missingAngleRad = missingAngleIntPerQuarter / 4 * Float(M_PI)
            let missingDistance = missingAngleRad * 180 / 100
            //println("angle:\(newAngle) \(tmpPi) miss:\(misPi)")

            /*
            let currDate = Int64(NSDate().timeIntervalSince1970 * 1000)
            var v:CGPoint
            //println("vx:\(self.prevDate) vy:\(currDate)")
            if(self.prevDate + 100 < currDate) {
                v = CGPoint(x: 0, y: 0)
            } else {
                let m = CGFloat(translation.x - self.prevTranslation.x)
                let s = CGFloat(currDate) - CGFloat(self.prevDate)
                v = CGPoint(
                    x:m * 1000 / s,
                    y:CGFloat(0))
            }
            //println("vx:\(v.x) vy:\(v.y)")
            */
            
            self.currentAngle = newAngle
            self.currentPos = newPos
            
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(0.3)
            newAngle = missingAngleRad + currentAngle
            newPos = missingDistance + currentPos
            
            let rotateMatrix = SCNMatrix4MakeRotation(newAngle, 0, 1, 0)
            let moveMatrix = SCNMatrix4MakeTranslation(newPos, 0, 0)
            geometryNode.transform = SCNMatrix4Mult(rotateMatrix, moveMatrix)
            
            SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.42, 0.0, 0.58, 1.0))
            SCNTransaction.setCompletionBlock({ () -> Void in
                self.currentAngle = newAngle
                self.currentPos = newPos
                //self.geometryNode.checkAngle()
                //println("vx:\(v.x) vy:\(v.y)")
            })
            SCNTransaction.commit()

            
            /*
            var maintainSpeed = CAKeyframeAnimation(keyPath: "position.x")
            
            let easeOut = CAMediaTimingFunction(controlPoints: 0.0,  1.0, 0.65, 1.0)
            
            //maintainSpeed.values   = [CGFloat(self.currentPos), CGFloat(self.currentPos) + (50 * 0.031415)];
            //maintainSpeed.values   = [0, 10 * 0.031415]; // = 170x
            maintainSpeed.values   = [CGFloat(self.currentPos), CGFloat(self.currentPos) + CGFloat(v.x * v.x / 1000 * 0.031415)];
            maintainSpeed.keyTimes = [0.0, 1.000000];
            maintainSpeed.timingFunctions = [easeOut];
            //maintainSpeed.duration = CFTimeInterval(v.x / 100);
            maintainSpeed.duration = CFTimeInterval(1);
            geometryNode.addAnimation(maintainSpeed, forKey: "jump and bounce")
            */
//            var jump = CAKeyframeAnimation(keyPath: "position.y")
            
//            let easeIn  = CAMediaTimingFunction(controlPoints: 0.35, 0.0, 1.0,  1.0)
//            let easeOut = CAMediaTimingFunction(controlPoints: 0.0,  1.0, 0.65, 1.0)
//            
//            jump.values   = [0.000000, 0.433333, 0.000000, 0.124444, 0.000000, 0.035111, 0.000000];
//            jump.keyTimes = [0.000000, 0.255319, 0.531915, 0.680851, 0.829788, 0.914894, 1.000000];
//            jump.timingFunctions = [easeOut,  easeIn,  easeOut,  easeIn,   easeOut,   easeIn  ];
//            jump.duration = 0.783333;
//            geometryNode.addAnimation(jump, forKey: "jump and bounce")
            //geometryNode.removeAllAnimations()
            
        }
        /*
        if(self.currTranslation != translation) {
            self.prevDate = self.currDate
            self.prevTranslation = self.currTranslation
            self.currDate = Int64(NSDate().timeIntervalSince1970 * 1000)
            self.currTranslation = translation
        }
        */
    }
}

