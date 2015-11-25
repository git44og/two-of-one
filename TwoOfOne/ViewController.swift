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


let kConfigScale:Float = 0.025

let kPhysicsElastic:Float = 20
let kTranslationZoom:Float = 17
let kRestingSpeed:Float = 10

let kCylinderCenter = SCNVector3Make(0, 0, 2910 * kConfigScale)
let kCameraPosition = SCNVector3Make(0, 32 * kConfigScale, 0)
let kDistanceWall:Float = 2414 * kConfigScale

let kLightLeftPosition = SCNVector3Make(-1000 * kConfigScale, -315 * kConfigScale, 1780 * kConfigScale)
let kLightLeftColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.4)
let kLightLeftAttenuationStartDistance = 1570 * CGFloat(kConfigScale)
let kLightLeftAttenuationEndDistance = 4420 * CGFloat(kConfigScale)// * 10

let kLightRightPosition = SCNVector3Make(950 * kConfigScale, -380 * kConfigScale, 1990 * kConfigScale)
let kLightRightColor = UIColor(red: 243/255, green: 255/255, blue: 239/255, alpha: 0.4)
let kLightRightAttenuationStartDistance = 1430 * CGFloat(kConfigScale)
let kLightRightAttenuationEndDistance = 3820 * CGFloat(kConfigScale)// * 10

// device roation handling
let kEaseRotation:Double = 1 / 48
let kMaxOutRotation:Float = Float(M_PI / 32)
let kMinRotationRate:Double = 0.02

// tile rotation
let kDelayTurnBack: NSTimeInterval = 1.0 //1.0
let kDurationTileTurn: NSTimeInterval = 0.3 //0.3

enum JFGameMode:Int {
    case Menu = 0
    case Playing = 1
    case PlayingIntro = 2
}

enum JFAlterViewIdentifier:Int {
    case GameExit = 1
}


class ViewController: UIViewController, SCNSceneRendererDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var gameMenuView: UIView!
    @IBOutlet weak var gameScoreBoardView: UIView!
    @IBOutlet weak var homeMenuView: UIView!
    @IBOutlet weak var playEasyButton: UIButton!
    @IBOutlet weak var playMediumButton: UIButton!
    @IBOutlet weak var playHardButton: UIButton!
    @IBOutlet weak var physicsButton: UIButton!
    @IBOutlet weak var bonusLabel: UILabel!
    @IBOutlet weak var turnLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    // Geometry
    var cylinderNode: JFSCNNode = JFSCNNode()
    var physicsWallNodes:[SCNNode] = []
    var gridWall:JFSCNWall = JFSCNWall()
    var cameraNode:SCNNode = SCNNode()
    var decorationNode:JFSCNWorld = JFSCNWorld()
    
    // Gestures
    var currentAngle: Float = 0.0
    var currentPos: Float = 0.0
    var currentPanTranslation: CGFloat = 0
    var sceneSizeFactor:Float = 1.0
    var panRecognizer = UIPanGestureRecognizer()
    var tapRecognizer = UITapGestureRecognizer()
    
    //physics version
    var translationX:Float = 0
    var panStartNodePos:SCNVector3 = SCNVector3()
    var panActive = false
    var panPaused = false
    var hitWallLeft = false
    var hitWallRight = false
    var centerNode = SCNNode()
    
    // core motion
    var cm:CMMotionManager = CMMotionManager()
    var lastEasedRotationRate = CMRotationRate()
    
    // game logic
    var game:Game = Game()
    var gameMode:JFGameMode = .Menu
    var turnedNodes:[JFTileNode] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.game = Game(vc: self)
        self.gameMenuView.hidden = true
        self.gameScoreBoardView.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        
        self.sceneSizeFactor = (Float)(sceneView.frame.size.height / sceneView.frame.size.width * 1.35)
        
        let scene = SCNScene()
        
        // lights
        self.addLights(scene)
        
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = false
        sceneView.delegate = self
        
        // camera
        self.addCamera(scene)
        
        // motion detection
        self.startDeviceMotionDetection()
    }
    
    func addCenterNode(scene:SCNScene) {
        self.centerNode = SCNNode()
        let gravityField = SCNPhysicsField.radialGravityField()
        gravityField.strength = 0
        self.centerNode.physicsField = gravityField
        self.centerNode.name = "gravity"
        self.sceneView.scene?.rootNode.addChildNode(self.centerNode)
        self.centerNode.opacity = 1.0
        self.centerNode.physicsField?.categoryBitMask = 1
    }
    
    func addCylinder(scene:SCNScene) {
        self.cylinderNode = JFSCNNode(sceneSize: sceneView.frame.size, game:self.game)
        
        scene.rootNode.addChildNode(self.cylinderNode)
        self.cylinderNode.generateTileNodes()
        let move = SCNMatrix4MakeTranslation(0, kCylinderCenter.y, self.cylinderNode.shapeRadius - kCylinderCenter.z)
        self.cylinderNode.transform = move
        self.cylinderNode.physicsBody?.resetTransform()
    }
    
    func addPhysicsWalls(scene:SCNScene) {
        if(!self.game.physics) {
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
        self.physicsWallNodes.append(wallRightNode)
        scene.rootNode.addChildNode(wallRightNode)
        
        let wallLeftShape = SCNFloor()
        let wallLeftPhysicsShape = SCNPhysicsShape(geometry: wallLeftShape, options: nil)
        let wallLeftPhysicsBody = SCNPhysicsBody(type: .Static, shape: wallLeftPhysicsShape)
        let wallLeftNode = SCNNode()
        wallLeftNode.physicsBody = wallLeftPhysicsBody
        wallLeftNode.transform = SCNMatrix4Mult(
            SCNMatrix4MakeRotation(-Float(M_PI_2), 0, 0, 1),
            SCNMatrix4MakeTranslation(-wallDist, 0, 0)
        )
        self.physicsWallNodes.append(wallLeftNode)
        scene.rootNode.addChildNode(wallLeftNode)
    }
    
    func addGridWall(scene:SCNScene) {
        self.gridWall = JFSCNWall(size: JFGridSize(width: self.game.cylinderCols(), height: self.game.cylinderRows()), game:self.game, type: JFWallTileType.grid)
        self.gridWall.position = SCNVector3Make(0, 0, -kCylinderCenter.z)
        scene.rootNode.addChildNode(self.gridWall)
    }
    
    func addDecoration(scene:SCNScene) {
        // wall
        self.decorationNode = JFSCNWorld(game: self.game)
        scene.rootNode.addChildNode(self.decorationNode)
    }
    
    func removeGameObjects() {
        // remove wall and cylinder when entering menu mode
        self.cylinderNode.removeFromParentNode()
        for wallNode in self.physicsWallNodes {
            wallNode.removeFromParentNode()
        }
        self.centerNode.removeFromParentNode()
        self.gridWall.removeFromParentNode()
        self.decorationNode.removeFromParentNode()
    }
    
    func addCamera(scene:SCNScene) {
        // camera
        self.cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.yFov = 17.5
        cameraNode.camera?.zFar = 200
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, 0, self.cylinderNode.shapeRadius - kCylinderCenter.z)
        let camMove = SCNMatrix4MakeTranslation(0, kCameraPosition.y, self.cylinderNode.shapeRadius - kCylinderCenter.z)
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
        
        let spotLeftLight = SCNLight()
        spotLeftLight.attenuationStartDistance = kLightLeftAttenuationStartDistance
        spotLeftLight.attenuationEndDistance = kLightLeftAttenuationEndDistance
        let spotLeftLightNode = SCNNode()
        spotLeftLightNode.light = spotLeftLight
        spotLeftLightNode.light!.type = SCNLightTypeOmni
        spotLeftLightNode.light!.color = kLightLeftColor
        
        let moveLeft = SCNMatrix4MakeTranslation(kLightLeftPosition.x, kLightLeftPosition.y, -kLightLeftPosition.z)
        spotLeftLightNode.transform = moveLeft
        scene.rootNode.addChildNode(spotLeftLightNode)
        
        let spotRightLight = SCNLight()
        spotRightLight.attenuationStartDistance = kLightRightAttenuationStartDistance
        spotRightLight.attenuationEndDistance = kLightRightAttenuationEndDistance
        let spotRightLightNode = SCNNode()
        spotRightLightNode.light = spotLeftLight
        spotRightLightNode.light!.type = SCNLightTypeOmni
        spotRightLightNode.light!.color = kLightRightColor
        
        let moveRight = SCNMatrix4MakeTranslation(kLightRightPosition.x, kLightRightPosition.y, -kLightRightPosition.z)
        spotRightLightNode.transform = moveRight
        scene.rootNode.addChildNode(spotRightLightNode)
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
    
    //MARK: acceleration handling
    
    func startDeviceMotionDetection() {
        // add core motion
        let queue:NSOperationQueue! = NSOperationQueue.currentQueue()
        cm.deviceMotionUpdateInterval = 0.2
        cm.startDeviceMotionUpdatesToQueue(queue) { (motionData:CMDeviceMotion?, error:NSError?) -> Void in
            if let myMotionData = motionData {
                self.rotatePointOfView(myMotionData.rotationRate)
            }
        }
    }
    
    func stopDeviceMotionDetection() {
        cm.stopDeviceMotionUpdates()
    }
    
    func rotatePointOfView(rotationRate:CMRotationRate) {
        //print("rX: \(rotationRate.y)")
        
        // use y cause of portrait mode
        //let easedRotationX:Float = (abs(rotationRate.y) > kMinRotationRate) ? Float(rotationRate.y * kEaseRotation) : 0
        let easedRotationX:Float = Float(rotationRate.y * kEaseRotation)
        let maxOutRotationX:Float = (abs(easedRotationX) > kMaxOutRotation) ? kMaxOutRotation * sign(easedRotationX) : easedRotationX
        let rotationX = (Float(self.lastEasedRotationRate.x * 2) + maxOutRotationX) / 3
        
        // use x cause of portrait mode
        //let easedRotationY:Float = (abs(rotationRate.x) > kMinRotationRate) ? Float(-rotationRate.x * kEaseRotation) : 0
        let easedRotationY:Float = Float(-rotationRate.x * kEaseRotation)
        let maxOutRotationY:Float = (abs(easedRotationY) > kMaxOutRotation) ? kMaxOutRotation * sign(easedRotationY) : easedRotationY
        let rotationY = (Float(self.lastEasedRotationRate.y * 2) + maxOutRotationY) / 3

        self.lastEasedRotationRate = CMRotationRate(x: Double(maxOutRotationX), y: Double(maxOutRotationY), z: 0)
        
        if((rotationX == 0) && (rotationY == 0)) {
            // no animation required
            return
        }
        let rotationVector = SCNVector4Make(rotationX, rotationY, 0, sqrt((rotationX * rotationX) + (rotationY * rotationY)))
        let rotateTo = SCNAction.rotateToAxisAngle(rotationVector, duration: 0.2)
        self.cameraNode.runAction(rotateTo)
    }
    
    //MARK: Gesture
    
    func addGestureRecognizers() {
        let panRecognizer = UIPanGestureRecognizer(target: self, action: self.game.physics ? "panGesturePhysics:" : "panGesture:")
        self.sceneView.addGestureRecognizer(panRecognizer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapGesture:")
        self.sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    func removeGestureRecognizers() {
        self.sceneView.removeGestureRecognizer(self.tapRecognizer)
        self.sceneView.removeGestureRecognizer(self.panRecognizer)
    }
    
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
//                        --- what means tile locked
//                        --- continue with turn count and score in game object
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
                execDelay(kDelayTurnBack) {
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
    
    //MARK: user actions
    func gamePlayIntro() {
        
        self.gameMenuView.hidden = false
        self.homeMenuView.hidden = true
//        self.gameScoreBoardView.hidden = false

        self.gameMode = .PlayingIntro
        self.addCylinder(self.sceneView.scene!)
        self.addPhysicsWalls(self.sceneView.scene!)
        self.addGridWall(self.sceneView.scene!)
        self.addDecoration(self.sceneView.scene!)
        if(self.game.physics) {
            self.addCenterNode(self.sceneView.scene!)
        }
        

        execDelay(0.5) { () -> () in
            let delayGamePlay = self.cylinderNode.foldAnimation()
            execDelay(delayGamePlay) { () -> () in
                self.gamePlay()
            }
        }
    }
    
    func gamePlay() {
        self.gameMode = .Playing
        self.addGestureRecognizers()
    }
    
    func gameExit() {
        self.removeGestureRecognizers()
        self.removeGameObjects()
        self.gameMode = .Menu
        self.homeMenuView.hidden = false
        self.gameMenuView.hidden = true
        self.gameScoreBoardView.hidden = true
    }
    
    //MARK: button actions
    
    @IBAction func onPlayPressed(sender: AnyObject) {
        switch(sender.tag) {
        case 1:
            self.game.level = 0
            self.gamePlayIntro()
            break
        case 2:
            self.game.level = 1
            self.gamePlayIntro()
            break
        case 3:
            self.game.level = 2
            self.gamePlayIntro()
            break
        default:
            break
        }
    }
    
    @IBAction func onMenuPressed(sender: AnyObject) {
        let alertView = UIAlertView(title:"Exit Game", message: "", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Ok")
        alertView.tag = JFAlterViewIdentifier.GameExit.rawValue
        alertView.show()
    }
    
    @IBAction func onPhysicsPressed(sender: AnyObject) {
        self.game.physics = !self.game.physics
        self.physicsButton.setTitle(self.game.physics ? "Physics On" : "Physics Off", forState: .Normal)
    }
    
    //MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        switch(alertView.tag) {
        case JFAlterViewIdentifier.GameExit.rawValue:
            
            // game exit alert view
            switch(buttonIndex) {
            case 1:
                // exit game
                self.gameExit()

                break
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    //MARK: SCNSceneRendererDelegate
    
    func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        // handle cylinder rotation
        switch(self.gameMode) {
        case .Menu:
            break
        case .Playing, .PlayingIntro:
            // adjust rotation based on position
            let location = self.cylinderNode.presentationNode.position
            let angle = -location.x / self.cylinderNode.shapeRadius
            //print("x:\(location.x)")
            let rotate = SCNMatrix4MakeRotation(angle, 0, -1, 0)
            self.cylinderNode.rotationNode.transform = rotate
            break
        }
    }
    
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        // takes care of cylinder movement
        if(!self.game.physics) {
            return
        }

        switch(self.gameMode) {
        case .Menu, .PlayingIntro:
            // nothing to do
            break
        case .Playing:
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
                let distBetweenFlatSpot = (self.cylinderNode.circumsize / Float(self.game.cylinderCols()))
                let widthHalfTile:Float = distBetweenFlatSpot / 2
                let targetPos = ((round((location.x + widthHalfTile) / distBetweenFlatSpot) + 0) * distBetweenFlatSpot) - widthHalfTile
                self.centerNode.position = SCNVector3Make(targetPos, 0, -kCylinderCenter.z)
                self.centerNode.physicsBody?.resetTransform()
                self.centerNode.physicsField?.strength = 10000
                //self.centerNode.opacity = 1
                //print("v:\(self.cylinderNode.physicsBody?.velocity)")
            }
            break
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.LandscapeLeft
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.LandscapeLeft
    }
}

