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
let kTileColorOpenInner = UIColor(white: 0.5, alpha: 0.5)
let kTileColorOpenOuter = UIColor(white: 0.5, alpha: 1)
let kTileColorOpenFrame = UIColor(white: 1, alpha: 1)
let kTileColorClosedInner = UIColor(red: 156/255, green: 230/255, blue: 255/255, alpha: 0.93)
let kTileColorClosedInnerTransparency = UIColor(white: 1.0, alpha: 1)
let kTileColorClosedOuter = UIColor(white: 1, alpha: 1)
let kTileColorClosedFrame = UIColor(white: 1, alpha: 1)
let kTileRestingPosition = SCNVector3Make(0, 1000, 0)


class JFSCNNode : SCNNode {

    var game:Game = Game()
    var nodesByCol:[[SCNNode]] = []
    var rotationNode = SCNNode()
    var shapeRadius: Float = 0
    var currentPosition: Float = 0
    var sceneSize: CGSize
    var sceneSizeFactor: Float
    var circumsize:Float = 1
    var rollBoundaries:Float = 1
    var tileGap:Float = 0
    
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
        //MARK: usePhysics
        if(usePhysics) {
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
        
        // shape
        
        for colId in 0...(self.game.cylinderCols() - 1) {
            
            self.nodesByCol.append([])
            
            let angle = tileAngleRad * Float(colId)
            let position = CGPoint(
                x: CGFloat(sin(angle)) * CGFloat(self.shapeRadius),
                y: CGFloat(cos(angle)) * CGFloat(self.shapeRadius))
            
            //println("radius:\(radius) angle:\(angle) x:\(position.x) y:\(position.y)")
            
            for rowId in 0...(self.game.cylinderRows() - 1) {
                // creating tile
                let tileNode = JFTileNode(
                    x: colId, y: rowId,
                    id: shuffledTileMap[((self.game.cylinderRows() * colId) + rowId)],
                    size:CGSize(width: CGFloat(self.game.cylinderTileWidth()), height: CGFloat(self.game.cylinderTileWidth())),
                    parent:self)
                tileNode.position = SCNVector3(
                    x: Float(position.x),
                    y: ((Float(rowId) - (Float(self.game.cylinderRows() - 1) / 2)) * (self.game.cylinderTileWidth() + self.tileGap)),
                    //y: ((Float(rowId) * self.game.cylinderTileWidth()) - (Float(self.game.cylinderRows() - 1) / 2)) * self.tileGap,
                    z: Float(position.y))
                tileNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: angle)
                tileNode.baseAngle = angle
                
                self.rotationNode.addChildNode(tileNode)
                self.addNodeToCol(tileNode, col:colId)
            }
        }
    }
    
    func addNodeToCol(node:SCNNode, col:Int) {
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
}


let blueColor = UIColor(red: 35/255, green: 153/255, blue: 218/255, alpha: 1)

enum JFTileNodeFaceType:Int {
    case transparent = 0
    case open = 1
    case closed
}

class JFTileNode: SCNNode {
    var turned:Bool = false
    var cylinderNode: JFSCNNode
    var baseAngle:Float = 0
    var typeId:Int = 0
    var nodeId:CGPoint
    var tileNodes:[JFTileNodeFaceType:SCNNode] = [:]
    let explosionImage = UIImage(named: "explosion")
    
    //MARK: tmp
    var vanished:Bool = false
    var lock:Bool = false
    
    init(x:Int, y:Int, id:Int, size:CGSize, parent:JFSCNNode) {
        
        self.nodeId = CGPoint(x: x, y: y)
        self.typeId = id
        self.cylinderNode = parent
        
        super.init()
        
        let extrusionDepth = size.width * kTileExtrusion
        
        // open tile
        let tileBaseShape = SCNBox(width: size.width, height: size.height, length: extrusionDepth, chamferRadius: 0)
        tileBaseShape.firstMaterial?.diffuse.contents = UIColor.clearColor()
        self.geometry = tileBaseShape
        
       // add visible nodes
        self.addFaces(size)
        
        self.adjustNodesVisibility()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.cylinderNode = JFSCNNode()
        fatalError("init(coder:) has not been implemented")
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
    
    func didTurn(completion: (() -> Void)!) {

        let rotationDuration:NSTimeInterval = 0.3
        
        // get half rotation in correct direction
        let rotationAngleInt:CGFloat = (self.turned ? 1 : -1)
        let rotationAngle:CGFloat = CGFloat(M_PI) * rotationAngleInt
        
        // find timing when tile faces have to change
        var timing:NSTimeInterval = 0.5
        if let parent = self.parentNode as? JFSCNNode {

            // get angle based on position of tile relative to camera
            let positionAbsolute = SCNVector3(
                x:(parent.position.x + self.position.x),
                y:(parent.position.y + self.position.y),
                z:(parent.position.z + self.position.z))
            let perpectveAngle = atan(positionAbsolute.x / positionAbsolute.z)
            // get initial global angle of tile by adding local tile angle, groupNode angle, global tile position
            let rootAngle = parent.rotation.w * ((parent.rotation.y > 0) ? 1 : -1) + self.baseAngle - perpectveAngle
            
            // get angle at which small side of tile faces camera
            let rootAngleInt = rootAngle / Float(M_PI)
            let targetAngleInt:Float = self.turned ? ceil(rootAngleInt + 0.5) - 0.5 : floor(rootAngleInt + 0.5) - 0.5
            timing = (NSTimeInterval(targetAngleInt) - NSTimeInterval(rootAngleInt)) / NSTimeInterval(rotationAngleInt)
            
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
            
            //println("rootAngle:\(rootAngleInt) timing:\(timing) tmp1:\(targetAngleInt)")
        }
        
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
        let movePush = SCNAction.moveBy(SCNVector3Make(self.position.x / -2, 0, self.position.z / -2), duration: 1.0)
        movePush.timingMode = SCNActionTimingMode.Linear
        
        let rotationCorrection:Float = (self.rotation.y < -0.5) ? -1 : 1
        let rotationVector = SCNVector3Make(sin(self.rotation.w + Float(M_PI_2)), 0, cos(self.rotation.w + Float(M_PI_2)) * rotationCorrection)
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
    
    func explode() {
        let path = UIBezierPath(roundedRect: CGRect(x: -0.5, y: -0.5, width: 1.0, height: 1.0), cornerRadius: 0.1)
        let tile = SCNShape(path: path, extrusionDepth: 0.05)
        
        let exp = SCNParticleSystem()
        exp.loops = false
        exp.birthRate = 1000
        exp.birthDirection = SCNParticleBirthDirection.Random
        exp.emissionDuration = 0.05
        exp.spreadingAngle = 0
        exp.particleDiesOnCollision = true
        exp.particleLifeSpan = 0.125
        exp.particleLifeSpanVariation = 0.125
        exp.particleVelocity = 30
        exp.particleVelocityVariation = 10
        exp.particleSize = 0.1
        exp.particleColor = blueColor
        exp.particleImage = explosionImage
        exp.imageSequenceRowCount = 4
        exp.imageSequenceColumnCount = 4
        exp.imageSequenceFrameRate = 128
        exp.dampingFactor = 5.0
        exp.emitterShape = tile
        self.addParticleSystem(exp)
        
        self.vanished = true
        self.runAction(SCNAction.sequence([
            SCNAction.waitForDuration(0.1),
            SCNAction.fadeOutWithDuration(0)]), completionHandler: { () -> Void in
                self.hidden = true
        })

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
        tileClosedFrameShape.firstMaterial?.diffuse.intensity = 1
        tileClosedFrameShape.firstMaterial?.transparent.contents = kTileColorClosedFrame
        tileClosedFrameShape.firstMaterial?.transparent.intensity = 0.19
        let tileClosedFrameNode = SCNNode(geometry: tileClosedFrameShape)
        tileClosedNode.addChildNode(tileClosedFrameNode)
        // closed node immer
        let tileClosedInnerShape = SCNShape(path: pathInner, extrusionDepth: extrusionDepth)
        tileClosedInnerShape.materials = self.material(.closed)
        let tileClosedInnerNode = SCNNode(geometry: tileClosedInnerShape)
        tileClosedInnerNode.transform = SCNMatrix4MakeTranslation(Float(stroke), Float(stroke), 0)
        tileClosedNode.addChildNode(tileClosedInnerNode)
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
            var materialFaces:[SCNMaterial] = Array()
            let face = SCNMaterial()
            face.diffuse.contents = kTileColorClosedInner
            face.diffuse.intensity = 0.52
            face.transparent.contents = kTileColorClosedInnerTransparency
            face.transparent.intensity = 0.07
            materialFaces += [face]
            materialFaces += [face]
            let face3 = SCNMaterial()
            face3.diffuse.contents = UIColor.clearColor()
            materialFaces += [face3]
            return materialFaces
        case .open:
            var materialFaces:[SCNMaterial] = Array()
            let face = SCNMaterial()
            face.diffuse.contents = self.openTileImage()
            materialFaces += [face]
            materialFaces += [face]
            let face3 = SCNMaterial()
            face3.diffuse.contents = kTileColorOpenFrame
            materialFaces += [face3]
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