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
let kWallDist:Float = 10
let kRestingSpeed:Float = 4

class ViewController: UIViewController, SCNSceneRendererDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    // Geometry
    var geometryNode: JFSCNNode = JFSCNNode()
    
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
        cameraNode.camera?.zFar = 200
        let camMove = SCNMatrix4MakeTranslation(0, 50, 0)
        let camRotate = SCNMatrix4MakeRotation(Float(M_PI) / -2, 1, 0, 0)
        cameraNode.transform = SCNMatrix4Mult(camRotate, camMove)
        scene.rootNode.addChildNode(cameraNode)
        
        self.sceneSizeFactor = (Float)(sceneView.frame.size.height / sceneView.frame.size.width * 1.35)
        
        
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
        scene.rootNode.addChildNode(ground)

        
        let groupNode = JFSCNNode(sceneSize: sceneView.frame.size)
        // cylinder physics
        let groupShape = SCNCylinder(radius: CGFloat(groupNode.shapeRadius), height: CGFloat(cylinderHeight))
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
            groupNode.physicsBody = groupBody
        }
        scene.rootNode.addChildNode(groupNode)
        groupNode.generateTileNodes()
        let move = SCNMatrix4MakeTranslation(0, groupNode.shapeRadius, 0)
        let rotate = SCNMatrix4MakeRotation(Float(M_PI) / 2, 1, 0, 0)
        groupNode.transform = SCNMatrix4Mult(rotate, move)

        
        groupBody.resetTransform()
        //groupNode.adjustTransparency()
        geometryNode = groupNode
        
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

        self.geometryNode.rollTransformation(deltaTranslation)
        
        if(sender.state == UIGestureRecognizerState.Ended) {
            
            self.geometryNode.rollToRestingPosition(true)
        }
    }
    
    func panGesturePhysics(sender: UIPanGestureRecognizer) {
        
        if(sender.state == UIGestureRecognizerState.Began) {
            self.translationX = 0
            self.panStartNodePos = self.geometryNode.presentationNode.position
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
        let location = self.geometryNode.presentationNode.position
        let angle = -location.x / self.geometryNode.shapeRadius
        let rotate = SCNMatrix4Mult(
            SCNMatrix4MakeRotation(Float(M_PI) / 2, 1, 0, 0),
            SCNMatrix4MakeRotation(angle, 0, 0, 1))
        let move = SCNMatrix4MakeTranslation(location.x, location.y, location.z)
        self.geometryNode.transform = SCNMatrix4Mult(rotate, move)
        self.geometryNode.physicsBody?.resetTransform()
        
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
        if((geometryNode.physicsBody!.velocity.x > 0) && (self.geometryNode.presentationNode.position.x > kWallDist)) {
            //print("hit wall on the right")
            self.panPaused = true
            self.hitWallRight = true
            let velocity = geometryNode.physicsBody!.velocity.x * -0.2
            geometryNode.physicsBody?.velocity = SCNVector3Make(velocity, 0, 0)
        }
        
        // collide with left wall
        if((geometryNode.physicsBody!.velocity.x < 0) && (self.geometryNode.presentationNode.position.x < -kWallDist)) {
            //print("hit wall on the left")
            self.panPaused = true
            self.hitWallLeft = true
            let velocity = geometryNode.physicsBody!.velocity.x * -0.2
            geometryNode.physicsBody?.velocity = SCNVector3Make(velocity, 0, 0)
        }
        
        if(self.panActive && !self.panPaused) {
            geometryNode.physicsBody?.velocity = SCNVector3Make(velocity, 0, 0)
            //print("apply velocity \(velocity) d:\(self.translationX) p:\(nodeTranslationX)")
        }
        
        // adjust angular velocity based on current velocity
        let angularVelocity:Float = geometryNode.physicsBody!.velocity.x / self.geometryNode.shapeRadius
        geometryNode.physicsBody?.angularVelocity = SCNVector4Make(0, 0, -1, angularVelocity)
        
        // add center weight node
        if((!self.panActive) && ((self.geometryNode.physicsBody?.velocity.x > -kRestingSpeed) && (self.geometryNode.physicsBody?.velocity.x < kRestingSpeed))) {
            let distBetweenFlatSpot = (self.geometryNode.shapeRadius * Float(M_PI) * 2) / Float(tileCols)
            let targetPos = round(location.x / distBetweenFlatSpot) * distBetweenFlatSpot
            self.centerNode.position = SCNVector3Make(targetPos, 0, 0)
            self.centerNode.physicsBody?.resetTransform()
            self.centerNode.physicsField?.strength = 10000
            self.centerNode.opacity = 1
            //print("v:\(self.geometryNode.physicsBody?.velocity)")
        }
    }
}

