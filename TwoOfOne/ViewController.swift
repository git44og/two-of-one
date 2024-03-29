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
let kEaseRotation:Double = 1 / 8
let kMaxOutRollTop:Double = -Double(M_PI / 4)
let kMaxOutRollBottom:Double = Double(M_PI / 4)
let kMaxOutPitch:Double = Double(M_PI / 4)
let kMinRotationRate:Double = 0.02

// tile rotation
let kDelayTurnBack: NSTimeInterval = 1.0 //1.0
let kDurationTileTurn: NSTimeInterval = 0.3 //0.3

enum JFGameMode:Int {
    case Menu = 0
    case Playing = 1
    case PlayingIntro = 2
    case Ready
}

enum JFAlterViewIdentifier:Int {
    case GameExit = 1
}


class ViewController: UIViewController, SCNSceneRendererDelegate, UIAlertViewDelegate, SCNPhysicsContactDelegate {
    
    @IBOutlet weak var bonusProgressBarView: JFProgressView!
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var gameMenuView: UIView!
    @IBOutlet weak var gameScoreBoardView: UIView!
    @IBOutlet weak var bonusLabel: UILabel!
    @IBOutlet weak var turnProgressBarView: JFProgressView!
    @IBOutlet weak var turnLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var scoreBlockBarView: JFScoreBlockView!
    @IBOutlet weak var gameFinishView: UIView!
    
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
    
    var scoreBoard:ScoreBoardView!
    
    // tmp
    var startingAttitudeRoll:Double?
    var startingAttitudePitch:Double?
    var timerForTiles:[NSTimer] = []
    var isInitialSimulation:Bool = true
    var isSimulationAfterPan:Bool = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        JFSoundManager.sharedInstance.preloadSounds()
        
        self.game.vc = self
        self.gameFinishView.alpha = 0
        self.scoreBoard = ScoreBoardView(game: self.game,
            scoreViews: [
                .Turn: self.turnLabel,
                .Time: self.bonusLabel,
                .Score: self.scoreLabel,
                .TimeProgress: self.bonusProgressBarView,
                .TurnProgress: self.turnProgressBarView,
                .ScoreProgress: self.scoreBlockBarView
            ])
        self.game.scoreBoard = self.scoreBoard
        self.game.event(.InitGame)

        self.applyState(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if(self.gameMode == .Playing) {
            // this state can be reached after sharing
            return
        }
        
        admTrackState(ADMTrackingState.gamePlaying)
        
        self.sceneSizeFactor = (Float)(sceneView.frame.size.height / sceneView.frame.size.width * 1.35)
        
        let scene = SCNScene()
        scene.physicsWorld.contactDelegate = self
        
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
        
        self.gameMode = .PlayingIntro
        self.addCylinder(self.sceneView.scene!)
        self.addPhysicsWalls(self.sceneView.scene!)
        self.addGridWall(self.sceneView.scene!)
        self.addDecoration(self.sceneView.scene!)
        if(self.game.physics) {
            self.addCenterNode(self.sceneView.scene!)
        }

        self.animation(true) { () -> Void in
            self.gamePlayIntro()
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func addCenterNode(scene:SCNScene) {
        self.centerNode = SCNNode()
        let gravityField = SCNPhysicsField.radialGravityField()
        gravityField.strength = 0
        self.centerNode.physicsField = gravityField
        self.centerNode.name = "gravity"
        self.sceneView.scene?.rootNode.addChildNode(self.centerNode)
        self.centerNode.opacity = 0.0
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
        if #available(iOS 9, *) {
            wallRightPhysicsBody.contactTestBitMask = 1
        }
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
        if #available(iOS 9, *) {
            wallLeftPhysicsBody.contactTestBitMask = 1
        }
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
        cm.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryZVertical, toQueue: queue) { (motionData:CMDeviceMotion?, error:NSError?) -> Void in
            if let myMotionData = motionData {
                self.cameraAttitude(myMotionData.attitude)
                //print("roll:\(myMotionData.attitude.roll) pitch:\(myMotionData.attitude.pitch) yaw:\(myMotionData.attitude.yaw)")
                // roll x | pitch y | yaw z
            }
        }
    }
    
    func stopDeviceMotionDetection() {
        cm.stopDeviceMotionUpdates()
    }
    
    func cameraAttitude(attitude:CMAttitude) {
        
        if let _ = self.startingAttitudeRoll {
            if((attitude.roll - self.startingAttitudeRoll!) > kMaxOutRollBottom) {
                self.startingAttitudeRoll = attitude.roll - kMaxOutRollBottom
            } else if((attitude.roll - self.startingAttitudeRoll!) < kMaxOutRollTop) {
                self.startingAttitudeRoll = attitude.roll - kMaxOutRollTop
            }
        } else {
            self.startingAttitudeRoll = attitude.roll
        }

        if let _ = self.startingAttitudePitch {
            if((attitude.pitch - self.startingAttitudePitch!) > kMaxOutPitch) {
                self.startingAttitudePitch = attitude.pitch - kMaxOutPitch
            } else if((attitude.pitch - self.startingAttitudePitch!) < -kMaxOutPitch) {
                self.startingAttitudePitch = attitude.pitch + kMaxOutPitch
            }
        } else {
            self.startingAttitudePitch = attitude.pitch
        }
        
        //print("roll: \(attitude.roll - self.startingAttitude!.roll)  pitch: \(attitude.pitch - self.startingAttitude!.pitch)  yaw: \(attitude.yaw - self.startingAttitude!.yaw)")
        let rotateTo = SCNAction.rotateToX(
            CGFloat(easeAngle((-attitude.roll + self.startingAttitudeRoll!) * kEaseRotation, maxTop: kMaxOutRollBottom, maxBottom: kMaxOutRollTop)),
            y: CGFloat(easeAngle((attitude.pitch - self.startingAttitudePitch!) * kEaseRotation, maxTop: kMaxOutPitch, maxBottom: -kMaxOutPitch)),
            z: 0,
            duration: 0.2)
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
                    
                    if(self.gameMode == .Ready) {
                        // start game
                        self.gameMode = .Playing
                        self.game.event(JFMoveType.StartGame)
                    }
                    
                    nodeFound = handleTurnedTile(hitNode)
                }
                i++
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
            self.isSimulationAfterPan = true
            self.panActive = false
            self.panPaused = false
        }
    }
    
    //MARK: tile turn handling

    func handleTurnedTile(hitNode:JFTileNode) -> Bool {
        self.fireAllTileAnimations()
        
        if((!self.game.enableBackOfTiles && !hitNode.isFacingCamera()) || hitNode.lock) {
            // tile locked or tile not facing camera
            // don't turn
            return false
        } else if(hitNode.turned) {
            // turning back tiles deactivated
            /*
            hitNode.flip(completion: { () -> Void in
                execOnMain({ () -> () in
                    self.game.event(.flipBackTile)
                })
            })
            for j in 0...(self.turnedNodes.count - 1) {
                if(self.turnedNodes[j] == hitNode) {
                    self.turnedNodes.removeAtIndex(j)
                }
            }
            */
            return true
        } else {
            self.turnedNodes.append(hitNode)
            let checkPairCompletion = self.checkPair()
            hitNode.flip(completion: { () -> Void in
                checkPairCompletion()
                execOnMain({ () -> () in
                    self.game.event(.flipTile, info:hitNode)
                })
            })
            return true
        }
    }
    
    func checkPair() -> (() -> Void)! {
        //print("check pair")
        if(turnedNodes.count >= 2) {
            if(self.turnedNodes[0].isPairWithTile(self.turnedNodes[1])) {
                
                let tile1 = self.turnedNodes[0]
                let tile2 = self.turnedNodes[1]
                self.turnedNodes = []
                tile1.lock = true
                tile2.lock = true
                tile1.found = true
                tile2.found = true
                tile2.isSecondOfPair = true
                
                execOnMain({ () -> () in
                    self.game.event(.findPair, info:[tile1, tile2])
                })
                
                let timer = NSTimer.scheduledTimerWithTimeInterval(kDelayTurnBack, target: self, selector: Selector("tilesStartFalling:"), userInfo: [tile1, tile2], repeats: false)
                self.timerForTiles.append(timer)

                let timerGameFinish = NSTimer.scheduledTimerWithTimeInterval(kDelayTurnBack, target: self, selector: Selector("checkGameSolved:"), userInfo: [tile1, tile2], repeats: false)
                self.timerForTiles.append(timerGameFinish)
                
                return{}
    
            } else {
                let tile1 = self.turnedNodes[0]
                let tile2 = self.turnedNodes[1]
                self.turnedNodes = []
                tile1.lock = true
                tile2.lock = true
                
                execOnMain({ () -> () in
                    self.game.event(.findNoPair)
                })
                
                let timer = NSTimer.scheduledTimerWithTimeInterval(kDelayTurnBack, target: self, selector: Selector("tilesTurnBack:"), userInfo: [tile1, tile2], repeats: false)
                self.timerForTiles.append(timer)

                return{}
            }
        }
        return {}
    }

    //MARK: animaton
    
    @objc func checkGameSolved(timer:NSTimer) {
        print("func checkGameSolved")
        if(self.cylinderNode.solved()) {
            self.gameSolved()
        }
    }
    
    @objc func tilesStartFalling(timer:NSTimer) {
        print("func tilesStartFalling")
        self.game.updateScoreBoard()
        if let tiles = timer.userInfo as? [AnyObject] {
            if(tiles.count == 2) {
                for i in 0...1 {
                    if let tile = tiles[i] as? JFTileNode {
                        tile.showScoreTile()
                        tile.tileFalls()
                    }
                }
            }
        }
    }
    
    @objc func tilesTurnBack(timer:NSTimer) {
        print("func tilesTurnBack")
        self.game.updateScoreBoard()
        if let tiles = timer.userInfo as? [AnyObject] {
            if(tiles.count == 2) {
                for i in 0...1 {
                    if let tile = tiles[i] as? JFTileNode {
                        tile.flip(completion: { () -> Void in
                            tile.lock = false
                        })
                    }
                }
            }
        }
    }
    
    func fireAllTileAnimations() {
        for timer in self.timerForTiles {
            timer.fire()
        }
    }
    
    func animation(fadeIn:Bool, completion: (() -> Void)?) {
        self.applyState(fadeIn)
        UIView.animateWithDuration(fadeIn ? 0.5 : 0.3,
            delay: fadeIn ? 1.0 : 0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: { () -> Void in
                self.applyState(!fadeIn)
            }) { (Bool) -> Void in
                execDelay(0, closure: { () -> () in
                    if let myCompletion = completion {
                        myCompletion()
                    }
                })
        }
    }
    
    func applyState(hidden:Bool) {
        if(hidden) {
            self.gameMenuView.alpha = 0.1
            self.gameScoreBoardView.alpha = 0.1
            self.sceneView.alpha = 0.1
            self.gameFinishView.alpha = 0
        } else {
            self.gameMenuView.alpha = 1
            self.gameScoreBoardView.alpha = 1
            self.sceneView.alpha = 1
            self.gameFinishView.alpha = 0
        }
    }
    
    func gamePlayIntro() {
        execDelay(0.5) { () -> () in
            let delayGamePlay = self.cylinderNode.foldAnimation()
            execDelay(delayGamePlay) { () -> () in
                self.gamePlay()
            }
        }
    }
    
    func gamePlay() {
        self.gameMode = .Ready
        self.addGestureRecognizers()
    }
    
    func gameSolved() {
        
        self.game.event(.FinishGame)
        
        admTrackAction(ADMTrackingAction.gameFinish, score: self.game.time, level: self.game.level.rawValue)
        
        JFHighScoreObject.sharedInstance.setScore(self.game.totalScore(), level: self.game.level)
        for subView in self.gameFinishView.subviews {
            switch(subView.tag) {
            case 1:
                // pair bonus
                if let label = subView as? UILabel {
                    label.text = String(NSString(format: "%i", self.game.score))
                }
                break
            case 2:
                // time bonus
                if let label = subView as? UILabel {
                    label.text = String(NSString(format: "%i", self.game.timeBonus()))
                }
                break
            case 3:
                // turn bonus
                if let label = subView as? UILabel {
                    label.text = String(NSString(format: "%i", self.game.turnBonus()))
                }
                break
            case 4:
                // total score
                if let label = subView as? UILabel {
                    label.text = String(NSString(format: "%i", self.game.totalScore()))
                }
                break
            default:
                break
            }
        }
        
        self.gameFinishView.alpha = 1
    }
    
    func gameExit() {
        
        admTrackAction(ADMTrackingAction.gameExit, score: self.game.time, level: self.game.level.rawValue)
        
        self.game.cancelBonusTimer()
        
        self.removeGestureRecognizers()
        
        self.animation(false) { () -> Void in
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("menuScreen") as! MenuViewController
            vc.menuAnimation = .GameEnd
            self.presentViewController(vc, animated: false, completion: nil)
        }
    }
    
    //MARK: button actions
    
    @IBAction func onMenuPressed(sender: AnyObject) {
        let alertView = UIAlertView(title:"Exit Game", message: "", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Ok")
        alertView.tag = JFAlterViewIdentifier.GameExit.rawValue
        alertView.show()
    }
    
    @IBAction func onGameFinishMenuPressed(sender: AnyObject) {
        // exit game
        self.gameExit()
    }
    
    @IBAction func onGameFinishPlayAgainPressed(sender: AnyObject) {
        
        admTrackAction(ADMTrackingAction.gamePlayAgain, score: self.game.time, level: self.game.level.rawValue)
        
        self.animation(false) { () -> Void in
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("gameScreen") as! ViewController
            vc.game.level = self.game.level
            // setup game in debugging mode
            if(kIsDebugMode) {
                vc.game.enableBackOfTiles = NSUserDefaults.standardUserDefaults().boolForKey(kOptionsEnableBackOfTile)
                vc.game.debugPairs = NSUserDefaults.standardUserDefaults().boolForKey(kOptionsEnableDebug)
            }
            self.presentViewController(vc, animated: false, completion: nil)
        }
    }
    
    @IBAction func onGameFinisSharePressed(sender: AnyObject) {
        // share game score
        let shareText = "Just scored \(self.game.totalScore()) points playing two of one."
        let shareImage = UIImage(named: "twoOfOne")!
        let controller = UIActivityViewController(activityItems: [shareText, shareImage], applicationActivities: nil);
        if #available(iOS 9.0, *) {
            controller.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop, UIActivityTypeOpenInIBooks]
        } else {
            controller.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop]
        };
        
        controller.completionWithItemsHandler = { (activityType:String?, completed:Bool, returnedItems:[AnyObject]?, activityError:NSError?) -> Void in
            if let _ = activityType {
                if(completed) {
                    admTrackShareAction(activityType!, score: self.game.time, level: self.game.level.rawValue)
                }
            }
        }
        
        self.presentViewController(controller, animated: true, completion: nil);
        
        
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
        case .Ready, .Playing, .PlayingIntro:
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
        case .Ready, .Playing:
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
            
            if(self.panActive && !self.panPaused) {
                cylinderNode.physicsBody?.velocity = SCNVector3Make(velocity, 0, 0)
                //print("apply velocity \(velocity) d:\(self.translationX) p:\(nodeTranslationX)")
            }
            
            // add center weight node
            if((!self.panActive) && ((self.cylinderNode.physicsBody?.velocity.x > -kRestingSpeed) && (self.cylinderNode.physicsBody?.velocity.x < kRestingSpeed))) {
                let targetPos = ((round((location.x + self.cylinderNode.widthHalfTile) / self.cylinderNode.distBetweenFlatSpot) + 0) * self.cylinderNode.distBetweenFlatSpot) - self.cylinderNode.widthHalfTile
                if(self.isSimulationAfterPan || !SCNVector3EqualToVector3(SCNVector3Make(targetPos, 0, -kCylinderCenter.z), self.centerNode.position)) {
                    self.isSimulationAfterPan = false
                    self.centerNode.position = SCNVector3Make(targetPos, 0, -kCylinderCenter.z)
                    self.centerNode.physicsBody?.resetTransform()
                    self.centerNode.physicsField?.strength = 8000
                }
                //self.centerNode.opacity = 0
                //print("v:\(self.cylinderNode.physicsBody?.velocity)")
            }
            
            if(self.isInitialSimulation) {
                // give cylinder a little push to start rolling and start gravity effect
                self.isInitialSimulation = false
                self.centerNode.physicsField?.strength = 2000
                cylinderNode.physicsBody?.velocity = SCNVector3Make(0.00001, 0, 0)
            }
            
            break
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.LandscapeLeft
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.LandscapeLeft
    }
    
    
    //MARK: SCNPhysicsContactDelegate
    
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        //contact.nodeA.isMemberOfClass(JFSCNNode)
        JFSoundManager.sharedInstance.play(.HitWall)
        
        self.panPaused = true
        if(self.cylinderNode.presentationNode.position.x > 0) {
            self.hitWallRight = true
        } else {
            self.hitWallLeft = true
        }

    }

}

