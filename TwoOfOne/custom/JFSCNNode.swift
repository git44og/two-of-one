//
//  SFSCNNode.swift
//  TwoOfOne
//
//  Created by Jens on 5/09/2015.
//  Copyright (c) 2015 Jens. All rights reserved.
//

import Foundation
import SceneKit


/*
sin = gegnkathete / hypo
sin(a) = z / radius
cos = ankathete / hypo
tan = gegen / an
*/


// config
let kTileFrameStroke:CGFloat = 0.02
let kTileCornerradius:CGFloat = 0.06
let kTileExtrusion:CGFloat = 0.06
let kTileColorOpenFrame = UIColor(white: 1, alpha: 1)
//let kTileColorClosedOutside = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.60)
let kTileColorClosedOutside = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
//let kTileColorClosedOutsideTransparency = UIColor(white: 0.4, alpha: 1.0)
let kTileColorClosedOutsideTransparency:CGFloat = 0.6

let kTileColorClosedOutsideIntensity:CGFloat = 1.0
//let kTileColorClosedInside = UIColor(red: 55/255, green: 79/255, blue: 87/255, alpha: 0.93)
let kTileColorClosedInside = UIColor(red: 55/255, green: 79/255, blue: 87/255, alpha: 1.0)
//let kTileColorClosedInsideTransparency = UIColor(white: 0.07, alpha: 1.0)
let kTileColorClosedInsideTransparency:CGFloat = 0.93

let kTileColorClosedInsideIntensity:CGFloat = 1.0
let kTileColorClosedFrame = UIColor(white: 1, alpha: 1)
let kTileColorClosedFrameIntensity:CGFloat = 1.0
let kTileRestingPosition = SCNVector3Make(0, 1000, 0)
let kFlipAnimationTime:NSTimeInterval = 1.0
let kFoldinAnimationTime:NSTimeInterval = 1.0

class JFSCNNode : SCNNode {

    var game:Game
    var nodesByCol:[[JFTileNode]] = []
    var rotationNode = SCNNode()
    var shapeRadius: Float = 0
    var currentPosition: Float = 0
    var sceneSize: CGSize
    var sceneSizeFactor: Float
    var circumsize:Float = 1
    var rollBoundaries:Float = 1
    var tileGap:Float = 0
    var tileColNodes:[JFCylinderColNode] = []
    
    override var transform: SCNMatrix4 {
        didSet {
            //// slow on device
            self.adjustTransparency()
        }
    }
    
    override var position: SCNVector3 {
        didSet {
            self.currentPosition = self.position.x
        }
    }
    
    override init() {
        self.game = Game()
        self.sceneSize = CGSize()
        self.sceneSizeFactor = 1
        super.init()
    }
    
    init(sceneSize:CGSize, game:Game) {
        
        self.sceneSize = sceneSize
        self.game = game
        self.sceneSizeFactor = (Float)(sceneSize.height / sceneSize.width * 1.35)
        
        super.init()
        
        self.addChildNode(self.rotationNode)
        
        // gap between tiles
        self.tileGap = (self.game.cylinderHeight() - (self.game.cylinderTileWidth() * Float(self.game.cylinderRows()))) / (Float(self.game.cylinderRows()) - 1)
        // circumsize of cylinder
        self.circumsize = (self.game.cylinderTileWidth() * Float(self.game.cylinderCols())) + (tileGap * (Float(self.game.cylinderCols()) - 1))
        // distance to wall
        self.rollBoundaries = (self.circumsize / 2) * 1.05
        // cylinder radius
        self.shapeRadius = self.circumsize / (2 * Float(M_PI))
        // angle between columns
        
        // cylinder physics
        if(self.game.physics) {
            let cylinderShapeShape = SCNBox(
                width: CGFloat(self.shapeRadius) * 2,
                height: CGFloat(self.game.cylinderHeight()),
                length: CGFloat(self.shapeRadius),
                chamferRadius: 0)
            let cylinderPhysicsShape = SCNPhysicsShape(geometry: cylinderShapeShape, options: nil)
            let cylinderPhysicsBody = SCNPhysicsBody(type: .Dynamic, shape: cylinderPhysicsShape)
            cylinderPhysicsBody.velocityFactor = SCNVector3Make(1, 0, 0)
            cylinderPhysicsBody.angularVelocityFactor = SCNVector3Make(0, 0, 0)
            cylinderPhysicsBody.friction = 0.0
            cylinderPhysicsBody.rollingFriction = 0.0
            cylinderPhysicsBody.damping = 0.999999
            cylinderPhysicsBody.categoryBitMask = 1
            // cylinder view
            self.physicsBody = cylinderPhysicsBody
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func foldAnimation() -> NSTimeInterval {
        for tileCol in self.nodesByCol {
            for tileNode in tileCol {
                tileNode.runAction(tileNode.appearAction)
            }
        }
        for colNode in self.tileColNodes {
            colNode.runAction(colNode.foldAction)
        }
        return kFoldinAnimationTime + kFlipAnimationTime
    }
    
    func generateTileNodes() {
        
        let tileAngleRad = Float(M_PI) * (2 / Float(self.game.cylinderCols()))

        // generate tileMap
        var tileMap:[Int] = []
        for colId in 0...(self.game.cylinderCols() - 1) {
            for rowId in 0...(self.game.cylinderRows() - 1) {
                let tileId:Int = ((self.game.cylinderRows() * colId) + rowId) / 2
                tileMap.append(tileId)
            }
        }
        let shuffledTileMap = shuffleList(tileMap)

        // setup column nodes
        // base column is touching the grid
        let baseColId = (self.game.cylinderCols() / 2)
        
        // animation basics
        let singleFoldLength:NSTimeInterval = kFoldinAnimationTime / NSTimeInterval(self.game.cylinderCols() / 2)
        let colDistance:Float = (self.tileGap + self.game.cylinderTileWidth()) / 2

        for colId in 0...(self.game.cylinderCols() - 1) {
            
            // connect column nodes
            self.tileColNodes.append(JFCylinderColNode(parent: self))
            if(colId == baseColId) {
                self.rotationNode.addChildNode(self.tileColNodes[baseColId])
            }
            if((colId > 0) && (colId <= baseColId)) {
                self.tileColNodes[colId].addChildNode(self.tileColNodes[(colId - 1)])
            } else if(colId > baseColId) {
                self.tileColNodes[(colId - 1)].addChildNode(self.tileColNodes[colId])
            }
            
            // set position and pivot point
            let angle = tileAngleRad * Float(colId)
            self.tileColNodes[colId].relAngle = angle
            
            if(colId == baseColId) {
                
                self.tileColNodes[baseColId].pivot = SCNMatrix4MakeTranslation(-colDistance, 0, 0)

                self.tileColNodes[baseColId].position = SCNVector3(
                    x: Float(sin(angle)) * self.shapeRadius,
                    y: 0,
                    z: Float(cos(angle)) * self.shapeRadius)
                self.tileColNodes[baseColId].rotation = SCNVector4(x: 0, y: 1, z: 0, w: angle)
                
                // base tile needs to be rotated by half the angle of other tiles
                let foldAction = SCNAction.rotateByAngle(
                    CGFloat(M_PI * 1) / CGFloat(self.game.cylinderCols()),
                    aroundAxis: SCNVector3(x: 0, y: 1, z: 0),
                    duration: singleFoldLength)
                let waitDuration = NSTimeInterval(self.game.cylinderCols() - colId - 1) * singleFoldLength
                let waitAction = SCNAction.waitForDuration(kFlipAnimationTime + waitDuration)
                self.tileColNodes[colId].foldAction = SCNAction.sequence([waitAction, foldAction])

            } else {
                let multiplier:Float = ((colId >= (self.game.cylinderCols() / 2)) ? -1 : 1)
                self.tileColNodes[colId].pivot = SCNMatrix4MakeTranslation(colDistance * multiplier, 0, 0)
                self.tileColNodes[colId].position = SCNVector3(
                    x: -colDistance * multiplier,
                    y: 0,
                    z: 0)
                let rotationAngle = -multiplier * Float(M_PI * 2) / Float(self.game.cylinderCols())
                //action fold all cols
                /*
                self.tileColNodes[colId].foldAction = SCNAction.rotateByAngle(
                    CGFloat(rotationAngle),
                    aroundAxis: SCNVector3(x: 0, y: 1, z: 0),
                    duration: 1.0)
                */
                //action fold from sides
                let foldAction = SCNAction.rotateByAngle(
                    CGFloat(rotationAngle),
                    aroundAxis: SCNVector3(x: 0, y: 1, z: 0),
                    duration: singleFoldLength)
                let waitDuration = (colId < baseColId) ? NSTimeInterval(colId) * singleFoldLength : NSTimeInterval(self.game.cylinderCols() - colId - 1) * singleFoldLength
                if(waitDuration == 0) {
                    foldAction.timingMode = .EaseIn
                } else if(abs(colId - baseColId) == 1) {
                    foldAction.timingMode = .EaseOut
                }
                let waitAction = SCNAction.waitForDuration(kFlipAnimationTime + waitDuration)
                self.tileColNodes[colId].foldAction = SCNAction.sequence([waitAction, foldAction])
            }
        }
        
        // add tiles to cylinder
        //for colId in 0...2 {
        //for colId in baseColId...baseColId {
        for colId in 0...(self.game.cylinderCols() - 1) {
            
            self.nodesByCol.append([])
            
            for rowId in 0...(self.game.cylinderRows() - 1) {
                // creating tile
                let tileNode = JFTileNode(
                    x: colId, y: rowId,
                    id: shuffledTileMap[((self.game.cylinderRows() * colId) + rowId)],
                    size:CGSize(width: CGFloat(self.game.cylinderTileWidth()), height: CGFloat(self.game.cylinderTileWidth())),
                    parent:self,
                    colNode:self.tileColNodes[colId])
                tileNode.position = SCNVector3(
                    x: 0,
                    y: ((Float(rowId) - (Float(self.game.cylinderRows() - 1) / 2)) * (self.game.cylinderTileWidth() + self.tileGap)),
                    z: 0)
                
                self.tileColNodes[colId].addChildNode(tileNode)
                self.addNodeToCol(tileNode, col:colId)
            }
        }
    }
    
    func addNodeToCol(node:JFTileNode, col:Int) {
        self.nodesByCol[col].append(node)
    }
    
    func adjustTransparency() {
        
        // calculation
        // duplicate calculation
        /*
        let tileWidthRad = tileWidthDeg * (Float(M_PI) / 180)
        let tileAngleRad = Float(M_PI) * (2 / Float(tileNum))
        let radius = Float(tileWidth) / tan(tileWidthRad)

        for colId in 0...(tileNum - 1) {
            
            let angle:Float = (tileAngleRad * Float(colId)) + (self.rotation.w * self.rotation.y)
            let dist:Float = cos(angle) * radius
            let distancePercentage:Float = (((dist / radius) + 1) / 2)
            let opacity:Float = (distancePercentage * 0.2) + 0.6
            
            //println("newAngle:\(self.rotation.w) y:\(self.rotation.y) dist:\(dist) opacity:\(opacity)")
            
            //for rowId in 0...0 {
            for rowId in 0...(tileRows - 1) {
                if let tileNode = self.nodesByCol[colId][rowId] as? JFTileNode {
                    tileNode.opacity = CGFloat(opacity)
                }
            }
        }
        let angleIntPerQuarter = (self.rotation.w / Float(M_PI)) * (Float(tileNum) / 2) // 45deg == 1 | 90deg == 2
        */
    }
    
    
    //MARK: Rolling transformation
    
    func rollTransformation(translationX:CGFloat) {
        
        // get position based on distance
        let deltaPos = Float(translationX) / kTranslationZoom
        let newPos = self.currentPosition + deltaPos
        
        let moveMatrix = SCNMatrix4MakeTranslation(newPos, self.position.y, self.position.z)
        
        // hit right wall
        if((newPos > self.rollBoundaries) && (deltaPos > 0)) {
            return
        }
        //hit left wall
        if((newPos < -self.rollBoundaries) && (deltaPos < 0)) {
            return
        }
        // transform node
        self.transform = moveMatrix
        self.currentPosition = newPos
    }
    
    func rollToRestingPosition(animated:Bool = true) {
        
        // get delta distance based on delta angle
        let distBetweenFlatSpot = (self.circumsize / Float(self.game.cylinderCols()))
        let widthHalfTile:Float = distBetweenFlatSpot / 2
        let newPos = ((round((self.currentPosition + widthHalfTile) / distBetweenFlatSpot) + 0) * distBetweenFlatSpot) - widthHalfTile
        let moveMatrix = SCNMatrix4MakeTranslation(newPos, self.position.y, self.position.z)
        
        SCNTransaction.begin()
        if(animated) {
            SCNTransaction.setAnimationDuration(0.3)
        }
        self.transform = moveMatrix
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.42, 0.0, 0.58, 1.0))
        SCNTransaction.setCompletionBlock({ () -> Void in
            self.currentPosition = newPos
        })
        SCNTransaction.commit()
    }
    
    func cylinderRotation() -> Float {
        // angle correction maps the front column to angle 0
        var rotation = (self.rotationNode.rotation.w * self.cylinderRotationOrientation()) + (Float(M_PI) / Float(self.game.cylinderCols()))
        // return value in ]-pi, +pi[
        rotation = normalizeAngle(rotation)
        return rotation
    }
    
    func cylinderRotationOrientation() -> Float {
        // returns direction of rotation vector
        return ((self.rotationNode.rotation.y > 0) ? 1 : -1)
    }
}


class JFCylinderColNode: SCNNode {
    
    var foldAction:SCNAction = SCNAction()
    var cylinderNode: JFSCNNode
    var relAngle:Float = 0
    
    override init() {
        self.cylinderNode = JFSCNNode()
        super.init()
    }
    
    init(parent:JFSCNNode) {
        self.cylinderNode = parent
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func globalPositionInCylinder() -> SCNVector3 {
        
        let cylinderRotation = self.cylinderNode.cylinderRotation()
        let cylinderRadius = self.cylinderNode.shapeRadius
        
        var globalAngle = cylinderRotation + self.relAngle
        // change angle > pi to negative angle
        globalAngle -= (globalAngle > Float(M_PI)) ? Float(2 * M_PI) : 0
        //print("cyl:\(cylR) col:\(colR) rad:\(colAngle)")
        
        // calculate global position
        let position = SCNVector3(
            x: Float(sin(globalAngle)) * cylinderRadius,
            y: 0,
            z: Float(cos(globalAngle)) * cylinderRadius)

        //print("x:\(position.x) y:\(position.y) rad:\(colAngle)")
        
        //return position based on angle of col and angle of cylinder
        return position
    }
    
    func globalPosition() -> SCNVector3 {
        
        let positionAbsolute = SCNVector3(
            x:(self.cylinderNode.presentationNode.position.x + globalPositionInCylinder().x),
            y:(self.cylinderNode.presentationNode.position.y + globalPositionInCylinder().y),
            z:(self.cylinderNode.presentationNode.position.z + globalPositionInCylinder().z))
        
        return positionAbsolute
    }
}


enum JFTileNodeFaceType:Int {
    case transparent = 0
    case open = 1
    case closed
}

class JFTileNode: SCNNode {
    var turned:Bool = false
    var cylinderNode: JFSCNNode
    var colNode: JFCylinderColNode
    var typeId:Int = 0
    var nodeId:CGPoint
    var tileNodes:[JFTileNodeFaceType:SCNNode] = [:]
    var appearAction:SCNAction = SCNAction()
    
    //MARK: tmp
    var vanished:Bool = false
    var lock:Bool = false
    
    init(x:Int, y:Int, id:Int, size:CGSize, parent:JFSCNNode, colNode:JFCylinderColNode) {
        
        self.nodeId = CGPoint(x: x, y: y)
        self.typeId = id
        self.cylinderNode = parent
        self.colNode = colNode
        
        super.init()
        
        let extrusionDepth = size.width * kTileExtrusion
        
        // open tile
        let tileBaseShape = SCNBox(width: size.width, height: size.height, length: extrusionDepth, chamferRadius: 0)
        tileBaseShape.firstMaterial?.diffuse.contents = UIColor.clearColor()
        self.geometry = tileBaseShape
        
       // add visible nodes
        self.addFaces(size)
        self.setupForAppearanceAnimation()
        self.adjustNodesVisibility()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.cylinderNode = JFSCNNode()
        self.colNode = JFCylinderColNode()
        fatalError("init(coder:) has not been implemented")
    }

    func setupForAppearanceAnimation() {
        self.opacity = 0.0
        self.rotation = SCNVector4Make(0, 1, 0, Float(M_PI_2))
        let durationFlip = kFlipAnimationTime / NSTimeInterval(self.cylinderNode.game.cylinderCols() + self.cylinderNode.game.cylinderRows() - 2)
        let timiningX = NSTimeInterval(CGFloat(self.cylinderNode.game.cylinderCols()) - 1 - self.nodeId.x) * durationFlip
        let timiningY = NSTimeInterval(CGFloat(self.cylinderNode.game.cylinderRows()) - 1 - self.nodeId.y) * durationFlip
        self.appearAction = SCNAction.sequence([
            SCNAction.waitForDuration(timiningX + timiningY),
            SCNAction.group([
                SCNAction.fadeInWithDuration(0.1),
                SCNAction.rotateToAxisAngle(SCNVector4(), duration: 0.3)])
        ])
    }
    
    func flip(animated:Bool = true, completion: (() -> Void)! = nil) {
        self.turned = !self.turned
        if(animated) {
            self.didTurn(completion)
        }
    }
    
    func adjustNodesVisibility() {
        self.tileNodes[JFTileNodeFaceType.open]?.opacity = self.turned ? 1.0 : 0.0
        self.tileNodes[JFTileNodeFaceType.closed]?.opacity = self.turned ? 0.0 : 1.0
    }
    
    func isFacingCamera() -> Bool {
        let positionAbsolute = self.colNode.globalPosition()
        let perspectveAngle = atan(positionAbsolute.x / positionAbsolute.z)
        let rootAngle = normalizeAngle(self.cylinderNode.cylinderRotation() + self.colNode.relAngle - perspectveAngle)
        //print("rootAngle:\(rootAngle)")
        return (abs(rootAngle) < Float(M_PI_2))
    }
    
    func didTurn(completion: (() -> Void)!) {
        
        let rotationDuration:NSTimeInterval = kDurationTileTurn
        
        // get half rotation in correct direction
        let rotationAngleInt:CGFloat = (self.turned ? 1 : -1)
        let rotationAngle:CGFloat = CGFloat(M_PI) * rotationAngleInt
        
        // find timing when tile faces have to change
        var timing:NSTimeInterval = 0.5

        // get angle based on position of tile relative to camera
        let positionAbsolute = self.colNode.globalPosition()
        let perspectveAngle = atan(positionAbsolute.x / positionAbsolute.z)
        
        // get initial global angle of tile by adding local tile angle, groupNode angle, global tile position
        let rootAngle = self.cylinderNode.cylinderRotation() + self.colNode.relAngle - perspectveAngle

        // get angle at which small side of tile faces camera
        let rootAngleInt = rootAngle / Float(M_PI)
        let targetAngleInt:Float = self.turned ? ceil(rootAngleInt + 0.5) - 0.5 : floor(rootAngleInt + 0.5) - 0.5
        timing = (NSTimeInterval(targetAngleInt) - NSTimeInterval(rootAngleInt)) / NSTimeInterval(rotationAngleInt)
        
        /*
        print("----")
        print("c.x:\(self.cylinderNode.presentationNode.position.x) c.z:\(self.cylinderNode.presentationNode.position.z)")
        print("r.x:\(self.colNode.globalPositionInCylinder().x) r.z:\(self.colNode.globalPositionInCylinder().z)")
        print("a.x:\(positionAbsolute.x) a.z:\(positionAbsolute.z)")
        print("rootAng:\(rootAngle) cylAngle:\(self.cylinderNode.cylinderRotation()) +colAng:\(self.colNode.relAngle) -persAng:\(perspectveAngle) timing:\(timing)")
        */
        /*
        0 -> 0.5
        0.2 -> 0.3 / 0.7
        0.4 -> 0.1 / 0.9
        1.4 -> 0.1 / 0.9
        rootAngleInt + (rotationAngle * timing) = F() 0.5 | -0.5 | 1.5 ...
        (F() - rootAngleInt) / rotationAngle
        0 -> 0.5 / -0.5
        0.4 -> 0.5 / -0.5
        1.4 -> 1.5 / 0.5
        
        1.4 -> 2.8 > 3.8 > ceil > 4 > 3 > 1.5
        1.4 -> 2.8 > 3.8 > floor > 3 > 2 > 1
        0.9 -> 1.8 > 2.8 > ceil > 3 > 2 > 1
        0.9 -> 1.8 > 2.8 > floor > 2 > 1 > 0.5
        */
        
        // run aminations
        let rotationAction = SCNAction.rotateByAngle(rotationAngle, aroundAxis: SCNVector3(x: 0, y: 1, z: 0), duration: rotationDuration)
        rotationAction.timingMode = SCNActionTimingMode.Linear
        self.runAction(rotationAction, completionHandler: completion)
        
        let nodeToHide = self.turned ? self.tileNodes[JFTileNodeFaceType.closed] : self.tileNodes[JFTileNodeFaceType.open]
        nodeToHide?.runAction(SCNAction.sequence([
            SCNAction.waitForDuration(rotationDuration * timing),
            SCNAction.fadeOutWithDuration(0)]))
        
        let nodeToShow = self.turned ? self.tileNodes[JFTileNodeFaceType.open] : self.tileNodes[JFTileNodeFaceType.closed]
        nodeToShow?.runAction(SCNAction.sequence([
            SCNAction.waitForDuration(rotationDuration * timing),
            SCNAction.fadeInWithDuration(0)]))
    }

    func tileFalls(completion: (() -> Void)? = nil) {
        
        let moveFall = SCNAction.moveBy(SCNVector3Make(0, -self.cylinderNode.game.cylinderHeight() * 2, 0), duration: 1.0)
        moveFall.timingFunction = {(time:Float) -> Float in
            return time * time
        }
        let movePush = SCNAction.moveBy(SCNVector3Make(0, 0, self.cylinderNode.shapeRadius / -1.5), duration: 1.0)
        movePush.timingMode = SCNActionTimingMode.Linear
        
        let rotationVector = SCNVector3Make(-1, 0, 0)
        //print("from x:\(self.rotation.x) y:\(self.rotation.y) z:\(self.rotation.z) z:\(self.rotation.w)")
        //print("to   x:\(rotationVector.x) y:\(rotationVector.y) z:\(rotationVector.z)")
        let rotatePush = SCNAction.rotateByAngle(CGFloat(M_PI) * 1, aroundAxis: SCNVector3Make(rotationVector.x, 0, rotationVector.z), duration: 1.0)
        rotatePush.timingMode = SCNActionTimingMode.EaseIn
        self.runAction(SCNAction.group([moveFall, movePush, rotatePush])) { () -> Void in
            self.opacity = 0
            self.position = kTileRestingPosition
            completion
        }
    }
    
    func openTileImage() -> UIImage {
        let tileId = (self.typeId % 10 + 1)
        let tileIdStr = (tileId < 10) ? "0\(tileId)" : String(tileId)
        return UIImage(named: "Karte\(tileIdStr)")!
    }
    
    func addFaces(size:CGSize) {
        
        let stroke = size.width * kTileFrameStroke
        let cornerRadius = size.width * kTileCornerradius
        let extrusionDepth = size.width * kTileExtrusion
        
        let path = UIBezierPath(roundedRect: CGRect(x: size.width / -2, y: size.height / -2, width: size.width, height: size.height), cornerRadius: cornerRadius)
        let pathOuter = bezierPathRoundedRectangle(size, stroke: stroke, cornerRadius: cornerRadius)
        let pathInner = UIBezierPath(roundedRect: CGRect(x: size.width / -2, y: size.height / -2, width: size.width - (stroke * 2), height: size.height - (stroke * 2)), cornerRadius: cornerRadius - stroke)
        
        // closed node
        let tileClosedNode = SCNNode()
        // closed node frame
        let tileClosedFrameShape = SCNShape(path: pathOuter, extrusionDepth: extrusionDepth)
        tileClosedFrameShape.firstMaterial?.diffuse.contents = kTileColorClosedFrame
        tileClosedFrameShape.firstMaterial?.diffuse.intensity = kTileColorClosedFrameIntensity
        let tileClosedFrameNode = SCNNode(geometry: tileClosedFrameShape)
        tileClosedNode.addChildNode(tileClosedFrameNode)
        
        // closed node inner
        let tileClosedInnerShape = SCNShape(path: pathInner, extrusionDepth: extrusionDepth*1)
        tileClosedInnerShape.materials = self.material(.closed)
        let tileClosedInnerNode = SCNNode(geometry: tileClosedInnerShape)
        tileClosedInnerNode.transform = SCNMatrix4MakeTranslation(Float(stroke), Float(stroke), 0)
        tileClosedNode.addChildNode(tileClosedInnerNode)
        self.tileNodes[JFTileNodeFaceType.closed] = tileClosedNode
        self.addChildNode(tileClosedNode)
        self.tileNodes[JFTileNodeFaceType.closed] = tileClosedNode
        self.addChildNode(tileClosedNode)

        // open node
        let tileOpenShape = SCNShape(path: path, extrusionDepth: extrusionDepth)
        // open tile appearance
        tileOpenShape.materials = self.material(.open)
        let tileOpenNode = SCNNode(geometry: tileOpenShape)
        self.tileNodes[JFTileNodeFaceType.open] = tileOpenNode
        self.addChildNode(tileOpenNode)
    }

    func material(type:JFTileNodeFaceType) -> [SCNMaterial] {
        switch(type) {
        case .closed:
            var materialFaces:[SCNMaterial] = [SCNMaterial(), SCNMaterial(), SCNMaterial()]
            materialFaces[0].diffuse.contents = kTileColorClosedOutside
            //materialFaces[0].doubleSided = true
            //materialFaces[0].diffuse.intensity = kTileColorClosedOutsideIntensity
            //materialFaces[0].transparent.contents = kTileColorClosedOutsideTransparency
            //materialFaces[0].transparent.intensity = 0.07
            materialFaces[0].transparency = kTileColorClosedOutsideTransparency

            materialFaces[1].diffuse.contents = kTileColorClosedInside
            //materialFaces[1].doubleSided = true
            //materialFaces[1].diffuse.intensity = kTileColorClosedInsideIntensity
            //materialFaces[1].transparent.contents = kTileColorClosedInsideTransparency
            materialFaces[1].transparency = kTileColorClosedInsideTransparency
            
            materialFaces[2].diffuse.contents = UIColor.whiteColor()
            materialFaces[2].transparency = 0.0
            return materialFaces
        case .open:
            var materialFaces:[SCNMaterial] = [SCNMaterial(), SCNMaterial(), SCNMaterial()]
            materialFaces[0].diffuse.contents = self.openTileImage()
            materialFaces[1].diffuse.contents = self.openTileImage()
            materialFaces[2].diffuse.contents = kTileColorOpenFrame
            return materialFaces
        default:
            break
        }
        return []
    }
    
    func isPairWithTile(tile:JFTileNode) -> Bool {
        return (self.typeId % 10) == (tile.typeId % 10)
    }
}