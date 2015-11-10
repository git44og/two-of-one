//
//  ViewController.swift
//  TwoOfOne
//
//  Created by Jens on 2/09/2015.
//  Copyright (c) 2015 Jens. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion


let usePhysics = true
let kPhysicsElastic:Float = 20
let kTranslationZoom:Float = 17
let kRestingSpeed:Float = 10

let kDistanceCamera:Float = 60
let kDistanceWall:Float = 20

let kLight1Color = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.6)
let kLight2Color = UIColor(red: 243/255, green: 255/255, blue: 239/255, alpha: 0.6)

class ViewController: UIViewController, SCNSceneRendererDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var menuButton: UIButton!
    
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
        
        scene.physicsWorld.gravity = SCNVector3Make(0, -10, 0)
        
        self.cylinderNode = JFSCNNode(sceneSize: sceneView.frame.size)
        // cylinder physics
        let cylinderShapeShape = SCNBox(
            width: CGFloat(self.cylinderNode.shapeRadius) * 2,
            height: CGFloat(cylinderHeight),
            length: CGFloat(self.cylinderNode.shapeRadius),
            chamferRadius: 0)
//        let groupShape = SCNCylinder(radius: CGFloat(self.cylinderNode.shapeRadius), height: CGFloat(cylinderHeight))
        let cylinderPhysicsShape = SCNPhysicsShape(geometry: cylinderShapeShape, options: nil)
        let cylinderPhysicsBody = SCNPhysicsBody(type: .Dynamic, shape: cylinderPhysicsShape)
        cylinderPhysicsBody.velocityFactor = SCNVector3Make(1, 0, 0)
        cylinderPhysicsBody.angularVelocityFactor = SCNVector3Make(0, 0, 0)
        cylinderPhysicsBody.friction = 0.0
        cylinderPhysicsBody.rollingFriction = 0.0
        cylinderPhysicsBody.damping = 0.999999
        cylinderPhysicsBody.categoryBitMask = 1
        // cylinder view
        //MARK: usePhysics
        if(usePhysics) {
            self.cylinderNode.physicsBody = cylinderPhysicsBody
        }
        scene.rootNode.addChildNode(self.cylinderNode)
        self.cylinderNode.generateTileNodes()
        let move = SCNMatrix4MakeTranslation(0, 0, self.cylinderNode.shapeRadius - kDistanceCamera)
        self.cylinderNode.transform = move
        cylinderPhysicsBody.resetTransform()
        //self.cylinderNode.adjustTransparency()
        
        self.addPhysicsWalls(scene)
        
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
            //let shape = SCNSphere(radius: 1)
            //shape.firstMaterial?.diffuse.contents = UIColor(white: 0.5, alpha: 1)
            //self.centerNode = SCNNode(geometry: shape)
            self.centerNode = SCNNode()
            let gravityField = SCNPhysicsField.radialGravityField()
            gravityField.strength = 0
            self.centerNode.physicsField = gravityField
            self.centerNode.name = "gravity"
            self.sceneView.scene?.rootNode.addChildNode(self.centerNode)
            self.centerNode.opacity = 1.0
            self.centerNode.physicsField?.categoryBitMask = 1
        }
        
        //--CMMotionManager.startAccelerometerUpdatesToQueue(<#T##CMMotionManager#>)
    }
    
    func addPhysicsWalls(scene:SCNScene) {
        if(!usePhysics) {
            return
        }
        
        let wallDist = (self.cylinderNode.circumsize / 2) + self.cylinderNode.shapeRadius
        
        let wallRightShape = SCNFloor()
        let wallRightPhysicsShape = SCNPhysicsShape(geometry: wallRightShape, options: nil)
        let wallRightPhysicsBody = SCNPhysicsBody(type: .Static, shape: wallRightPhysicsShape)
        let wallRightNode = SCNNode()
        wallRightNode.physicsBody = wallRightPhysicsBody
        wallRightNode.transform = SCNMatrix4Mult(
            SCNMatrix4MakeRotation(Float(M_PI_2), 0, 0, 1),
            SCNMatrix4MakeTranslation(wallDist, 0, 0)
        )
        scene.rootNode.addChildNode(wallRightNode)
        
        let wallLeftShape = SCNFloor()
        let wallLeftPhysicsShape = SCNPhysicsShape(geometry: wallLeftShape, options: nil)
        let wallLeftPhysicsBody = SCNPhysicsBody(type: .Static, shape: wallLeftPhysicsShape)
        let wallLeftNode = SCNNode()
        wallLeftNode.physicsBody = wallLeftPhysicsBody
        wallLeftNode.transform = SCNMatrix4Mult(
            SCNMatrix4MakeRotation(-Float(M_PI_2), 0, 0, 1),
            SCNMatrix4MakeTranslation(-wallDist, 0, 0))
        scene.rootNode.addChildNode(wallLeftNode)
    }
    
    func addCamera(scene:SCNScene) {
        // camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
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
        //scene.rootNode.addChildNode(ambientLightNode)
        
        let spot1Light = SCNLight()
        spot1Light.attenuationStartDistance = 50
        spot1Light.attenuationEndDistance = 220
        let spot1LightNode = SCNNode()
        spot1LightNode.light = spot1Light
        spot1LightNode.light!.type = SCNLightTypeOmni
        spot1LightNode.light!.color = kLight1Color
        
        let move1 = SCNMatrix4MakeTranslation(-15, 0, 0)
        spot1LightNode.transform = move1
        scene.rootNode.addChildNode(spot1LightNode)
        
        let spot2Light = SCNLight()
        spot2Light.attenuationStartDistance = 50
        spot2Light.attenuationEndDistance = 220
        let spot2LightNode = SCNNode()
        spot2LightNode.light = spot1Light
        spot2LightNode.light!.type = SCNLightTypeOmni
        spot2LightNode.light!.color = kLight2Color
        
        let move2 = SCNMatrix4MakeTranslation(15, 0, 0)
        spot2LightNode.transform = move2
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
    
    func addUIButtonLayer() {
        
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
                    tile1.tileFalls()
                    tile2.tileFalls()
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
            //self.centerNode.opacity = 0.1
        }
        self.translationX = Float(sender.translationInView(sender.view!).x)
        
        if(sender.state == UIGestureRecognizerState.Ended) {
            self.panActive = false
            self.panPaused = false
        }
    }
    
    
    @IBAction func onMenuPressed(sender: AnyObject) {
        print("Menu")
    }
    
    //MARK: SCNSceneRendererDelegate
    
    func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        // adjust rotation based on position
        let widthHalfTile:Float = (self.cylinderNode.circumsize / Float(tileCols)) / 2
        let location = self.cylinderNode.presentationNode.position
        let angle = (-location.x + widthHalfTile) / self.cylinderNode.shapeRadius
        let rotate = SCNMatrix4MakeRotation(angle, 0, -1, 0)
        self.cylinderNode.rotationNode.transform = rotate
    }
    
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //MARK:usePhysics
        if(!usePhysics) {
            return
        }

        // calculate velocity
        let location = self.cylinderNode.presentationNode.position
        let nodeTranslationX = location.x - self.panStartNodePos.x
        let velocity:Float = ((Float(self.translationX) / kTranslationZoom) - nodeTranslationX) * kPhysicsElastic
        
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
        }
        
        // collide with left wall
        if((cylinderNode.physicsBody!.velocity.x < 0) && (self.cylinderNode.presentationNode.position.x < -self.cylinderNode.rollBoundaries)) {
            //print("hit wall on the left")
            self.panPaused = true
            self.hitWallLeft = true
        }
        
        if(self.panActive && !self.panPaused) {
            cylinderNode.physicsBody?.velocity = SCNVector3Make(velocity, 0, 0)
            //print("apply velocity \(velocity) d:\(self.translationX) p:\(nodeTranslationX)")
        }
        
        // add center weight node
        if((!self.panActive) && ((self.cylinderNode.physicsBody?.velocity.x > -kRestingSpeed) && (self.cylinderNode.physicsBody?.velocity.x < kRestingSpeed))) {
            let distBetweenFlatSpot = (self.cylinderNode.circumsize / Float(tileCols))
            let widthHalfTile:Float = distBetweenFlatSpot / 2
            let targetPos = ((round((location.x + widthHalfTile) / distBetweenFlatSpot) + 0) * distBetweenFlatSpot) - widthHalfTile
            self.centerNode.position = SCNVector3Make(targetPos, 0, -kDistanceCamera)
            self.centerNode.physicsBody?.resetTransform()
            self.centerNode.physicsField?.strength = 10000
            //self.centerNode.opacity = 1
            //print("v:\(self.cylinderNode.physicsBody?.velocity)")
        }
    }
}

