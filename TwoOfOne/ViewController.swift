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
    var currentPanTranslation: CGFloat = 0
    
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
        omniLightNode.position = SCNVector3Make(50, 0, 50)
        scene.rootNode.addChildNode(omniLightNode)
        
        // camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        //cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.yFov = 20
        //cameraNode.position = SCNVector3Make(0, 0, 21)
        scene.rootNode.addChildNode(cameraNode)
        
        self.sceneSizeFactor = (Float)(sceneView.frame.size.height / sceneView.frame.size.width * 1.35)
        
        // group
        let groupNode = JFSCNNode(sceneSize: sceneView.frame.size)
        //groupNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI / -4))
        groupNode.position = SCNVector3(x: 0, y: 0, z: -21)
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
            var i = 0
            var nodeFound = false
            while((i < objs.count) && !nodeFound) {
                let nearestObject = objs[0] as! SCNHitTestResult
                if let hitNode = nearestObject.node as? JFTileNode {
                    hitNode.flip()
                    nodeFound = true
                }
            }
        }
    }
    
    func panGesture(sender: UIPanGestureRecognizer) {
        
        if(sender.state == UIGestureRecognizerState.Began) {
            self.currentPanTranslation = 0
        }
        
        // get distance moved
        let translation = sender.translationInView(sender.view!)
        let deltaTranslation = translation.x - currentPanTranslation
        self.currentPanTranslation = translation.x

        self.geometryNode.rollTransformation(deltaTranslation)
        
        if(sender.state == UIGestureRecognizerState.Ended) {
            
            self.geometryNode.rollToRestingPosition(animated: true)
            /*
            var jump = CAKeyframeAnimation(keyPath: "position.y")
            
            let easeIn  = CAMediaTimingFunction(controlPoints: 0.35, 0.0, 1.0,  1.0)
            let easeOut = CAMediaTimingFunction(controlPoints: 0.0,  1.0, 0.65, 1.0)
            
            jump.values   = [0.000000, 0.433333, 0.000000, 0.124444, 0.000000, 0.035111, 0.000000];
            jump.keyTimes = [0.000000, 0.255319, 0.531915, 0.680851, 0.829788, 0.914894, 1.000000];
            jump.timingFunctions = [easeOut,  easeIn,  easeOut,  easeIn,   easeOut,   easeIn  ];
            jump.duration = 0.783333;
            geometryNode.addAnimation(jump, forKey: "jump and bounce")
            */
            
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

