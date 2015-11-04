//
//  ViewController.swift
//  TwoOfOne
//
//  Created by Jens on 2/09/2015.
//  Copyright (c) 2015 Jens. All rights reserved.
//

import UIKit
import SceneKit

let usePhysics = true
let kPhysicsElastic:Float = 20
let kPhysicsZoom:Float = 17
let kRestingSpeed:Float = 10
let kDistanceCamera:Float = 60
let kDistanceWall:Float = 10

class ViewController: UIViewController, SCNSceneRendererDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    // Geometry
    var cylinderNode: JFSCNNode = JFSCNNode()
    
    // Gestures
    var currentAngle: Float = 0.0
    var currentPos: Float = 0.0
    var currentPanTranslation: CGFloat = 0
    
    var sceneSizeFactor:Float = 1.0
    
    //tmp
    var turnedNodes:[JFTileNode] = []
    
    //physics version
    var translationX:Float = 0
    var panStartNodePos:SCNVector3 = SCNVector3()
    var panActive = false
    var panPaused = false
    var hitWallLeft = false
    var hitWallRight = false
    var centerNode = SCNNode()
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        self.sceneSizeFactor = (Float)(sceneView.frame.size.height / sceneView.frame.size.width * 1.35)
        
        let scene = SCNScene()
        
        // camera
        self.addCamera(scene)
        
        // lights
        self.addLights(scene)
        
        // decoration
        self.addDecoration(scene)
        
        self.cylinderNode = JFSCNNode(sceneSize: sceneView.frame.size)
        // cylinder physics
        let groupShape = SCNCylinder(radius: CGFloat(self.cylinderNode.shapeRadius), height: CGFloat(cylinderHeight))
        let groupPhysicsShape = SCNPhysicsShape(geometry: groupShape, options: nil)
        let groupBody = SCNPhysicsBody(type: .Dynamic , shape: groupPhysicsShape)
        groupBody.velocityFactor = SCNVector3Make(1, 0, 0)
        //groupBody.radius = self.radius
        groupBody.angularVelocityFactor = SCNVector3Make(0, 0, 1)
        groupBody.friction = 1.0
        groupBody.rollingFriction = 0.0
        groupBody.damping = 0.999999
        // cylinder view
        //MARK: usePhysics
        if(usePhysics) {
            self.cylinderNode.physicsBody = groupBody
        }
        scene.rootNode.addChildNode(self.cylinderNode)
        self.cylinderNode.generateTileNodes()
        let move = SCNMatrix4MakeTranslation(0, 0, self.cylinderNode.shapeRadius - kDistanceCamera)
        self.cylinderNode.transform = move
        groupBody.resetTransform()
        //self.cylinderNode.adjustTransparency()
        
        //MARK: usePhysics
        let panRecognizer = UIPanGestureRecognizer(target: self, action: usePhysics ? "panGesturePhysics:" : "panGesture:")
        sceneView.addGestureRecognizer(panRecognizer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapGesture:")
        sceneView.addGestureRecognizer(tapRecognizer)
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = false
        sceneView.delegate = self
        
        //MARK: usePhysics
        if(usePhysics) {
            let shape = SCNSphere(radius: 1)
            shape.firstMaterial?.diffuse.contents = UIColor(white: 0.5, alpha: 1)
            self.centerNode = SCNNode(geometry: shape)
            let gravityField = SCNPhysicsField.radialGravityField()
            //let gravityField = SCNPhysicsField.springField()
            gravityField.strength = 0
            self.centerNode.physicsField = gravityField
            self.centerNode.name = "gravity"
            self.sceneView.scene?.rootNode.addChildNode(self.centerNode)
            self.centerNode.opacity = 0.1
        }
    }
    
    func addCamera(scene:SCNScene) {
        // camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        //cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.yFov = 20
        cameraNode.camera?.zFar = 200
        let camMove = SCNMatrix4MakeTranslation(0, 0, 0)
//        let camMove = SCNMatrix4MakeTranslation(0, 30, 0)
        cameraNode.transform = camMove
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func addLights(scene:SCNScene) {
        // light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor(white: 0.67, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLightTypeOmni
        omniLightNode.light!.color = UIColor(white: 1, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(50, 0, 50)
        scene.rootNode.addChildNode(omniLightNode)
        
        let spot1Light = SCNLight()
        spot1Light.attenuationStartDistance = 50
        spot1Light.attenuationEndDistance = 70
        spot1Light.spotInnerAngle = 30
        spot1Light.spotOuterAngle = 45
        let spot1LightNode = SCNNode()
        spot1LightNode.light = spot1Light
        spot1LightNode.light!.type = SCNLightTypeSpot
        spot1LightNode.light!.color = UIColor(white: 1, alpha: 1.0)
        spot1LightNode.position = SCNVector3Make(10, 0, 10)
        
        let move1 = SCNMatrix4MakeTranslation(-15, kDistanceCamera, 0)
        let rotate1 = SCNMatrix4MakeRotation(Float(M_PI) / -2, 1, 0, 0)
        spot1LightNode.transform = SCNMatrix4Mult(rotate1, move1)
        scene.rootNode.addChildNode(spot1LightNode)
        
        let spot2Light = SCNLight()
        spot2Light.attenuationStartDistance = 50
        spot2Light.attenuationEndDistance = 70
        spot2Light.spotInnerAngle = 30
        spot2Light.spotOuterAngle = 45
        let spot2LightNode = SCNNode()
        spot2LightNode.light = spot1Light
        spot2LightNode.light!.type = SCNLightTypeSpot
        spot2LightNode.light!.color = UIColor(white: 1, alpha: 1.0)
        spot2LightNode.position = SCNVector3Make(10, 0, 10)
        
        let move2 = SCNMatrix4MakeTranslation(15, kDistanceCamera, 0)
        let rotate2 = SCNMatrix4MakeRotation(Float(M_PI) / -2, 1, 0, 0)
        spot2LightNode.transform = SCNMatrix4Mult(rotate2, move2)
        scene.rootNode.addChildNode(spot2LightNode)

    }
    
    func addDecoration(scene:SCNScene) {
        
        // wall
        scene.rootNode.addChildNode(JFSCNWorld())
        
        // ground
        let groundGeometry = SCNFloor()
        let groundShape = SCNPhysicsShape(geometry: groundGeometry, options: nil)
        let groundBody = SCNPhysicsBody(type: .Static, shape: groundShape)
        let groundMaterial = SCNMaterial()
        //groundMaterial.diffuse.contents = UIColor(white: 0.5, alpha: 1)
        groundMaterial.diffuse.contents = UIColor.redColor()
        groundGeometry.materials = [groundMaterial]
        let ground = SCNNode(geometry: groundGeometry)
        ground.physicsBody = groundBody
        ground.physicsBody?.friction = 1.0
        ground.name = "floor"
        //scene.rootNode.addChildNode(ground)
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
        let objs = self.sceneView.hitTest(translation, options: nil)
        if(objs.count > 0) {
            var i = 0
            var nodeFound = false
            while((i < objs.count) && !nodeFound) {
                let nearestObject = objs[i]
                if let hitNode = nearestObject.node as? JFTileNode {
                    if(hitNode.lock) {
                        // tile locked
                    } else if(hitNode.turned) {
                        hitNode.flip()
                        for j in 0...(self.turnedNodes.count - 1) {
                            if(self.turnedNodes[j] == hitNode) {
                                self.turnedNodes.removeAtIndex(j)
                            }
                        }
                        nodeFound = true
                    } else {
                        hitNode.flip()
                        self.turnedNodes.append(hitNode)
                        nodeFound = true
                    }
                }
                i++
            }
        }
        
        if(turnedNodes.count >= 2) {
            if(self.turnedNodes[0].isPairWithTile(self.turnedNodes[1])) {
                let tile1 = self.turnedNodes[0]
                let tile2 = self.turnedNodes[1]
                self.turnedNodes = []
                tile1.lock = true
                tile2.lock = true
                execDelay(1) {
                    tile1.explode()
                    tile2.explode()
                }
            } else {
                let tile1 = self.turnedNodes[0]
                let tile2 = self.turnedNodes[1]
                self.turnedNodes = []
                tile1.lock = true
                tile2.lock = true
                execDelay(1) {
                    tile1.flip(completion: { () -> Void in
                        tile1.lock = false
                    })
                    tile2.flip(completion: { () -> Void in
                        tile2.lock = false
                    })
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

        self.cylinderNode.rollTransformation(deltaTranslation)
        
        if(sender.state == UIGestureRecognizerState.Ended) {
            
            self.cylinderNode.rollToRestingPosition(true)
        }
    }
    
    func panGesturePhysics(sender: UIPanGestureRecognizer) {
        
        if(sender.state == UIGestureRecognizerState.Began) {
            self.translationX = 0
            self.panStartNodePos = self.cylinderNode.presentationNode.position
            self.panActive = true
            self.panPaused = false
            self.hitWallLeft = false
            self.hitWallRight = false
            self.centerNode.physicsField?.strength = 0
            self.centerNode.opacity = 0.1
        }
        self.translationX = Float(sender.translationInView(sender.view!).x)
        
        if(sender.state == UIGestureRecognizerState.Ended) {
            self.panActive = false
            self.panPaused = false
        }
    }
    
    
    //MARK: SCNSceneRendererDelegate
    
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //MARK:usePhysics
        if(!usePhysics) {
            return
        }

        // adjust rotation based on position
        let location = self.cylinderNode.presentationNode.position
        let angle = -location.x / self.cylinderNode.shapeRadius
        let rotate = SCNMatrix4MakeRotation(angle, 0, -1, 0)
        let move = SCNMatrix4MakeTranslation(location.x, location.y, location.z)
        self.cylinderNode.transform = SCNMatrix4Mult(rotate, move)
        self.cylinderNode.physicsBody?.resetTransform()
        
        // calculate velocity
        let nodeTranslationX = location.x - self.panStartNodePos.x
        let velocity:Float = ((Float(self.translationX) / kPhysicsZoom) - nodeTranslationX) * kPhysicsElastic
        
        // reactivate panning after hit - check if pan is going the other way
        if(self.hitWallRight && (velocity < 0)) {
            //print("right wall reactivate")
            self.panPaused = false
            self.hitWallRight = false
        }
        if(self.hitWallLeft && (velocity > 0)) {
            //print("left wall reactivate")
            self.panPaused = false
            self.hitWallLeft = false
        }
        
        // collide with right wall
        if((cylinderNode.physicsBody!.velocity.x > 0) && (self.cylinderNode.presentationNode.position.x > self.cylinderNode.rollBoundaries)) {
            //print("hit wall on the right")
            self.panPaused = true
            self.hitWallRight = true
            let velocity = cylinderNode.physicsBody!.velocity.x * -0.2
            cylinderNode.physicsBody?.velocity = SCNVector3Make(velocity, 0, 0)
        }
        
        // collide with left wall
        if((cylinderNode.physicsBody!.velocity.x < 0) && (self.cylinderNode.presentationNode.position.x < -self.cylinderNode.rollBoundaries)) {
            //print("hit wall on the left")
            self.panPaused = true
            self.hitWallLeft = true
            let velocity = cylinderNode.physicsBody!.velocity.x * -0.2
            cylinderNode.physicsBody?.velocity = SCNVector3Make(velocity, 0, 0)
        }
        
        if(self.panActive && !self.panPaused) {
            cylinderNode.physicsBody?.velocity = SCNVector3Make(velocity, 0, 0)
            //print("apply velocity \(velocity) d:\(self.translationX) p:\(nodeTranslationX)")
        }
        
        // adjust angular velocity based on current velocity
        let angularVelocity:Float = cylinderNode.physicsBody!.velocity.x / self.cylinderNode.shapeRadius
        cylinderNode.physicsBody?.angularVelocity = SCNVector4Make(0, 0, -1, angularVelocity)
        
        // add center weight node
        if((!self.panActive) && ((self.cylinderNode.physicsBody?.velocity.x > -kRestingSpeed) && (self.cylinderNode.physicsBody?.velocity.x < kRestingSpeed))) {
            let distBetweenFlatSpot = (self.cylinderNode.shapeRadius * Float(M_PI) * 2) / Float(tileCols)
            let targetPos = round(location.x / distBetweenFlatSpot) * distBetweenFlatSpot
            self.centerNode.position = SCNVector3Make(targetPos, 0, -kDistanceCamera)
            self.centerNode.physicsBody?.resetTransform()
            self.centerNode.physicsField?.strength = 10000
            self.centerNode.opacity = 1
            //print("v:\(self.cylinderNode.physicsBody?.velocity)")
        }
    }
}

