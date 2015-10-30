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
let tileWidth:Float = 2
let cylinderHeight:Float = 15.0
let tileRows:Int = 6
let tileCols:Int = 6

//let tileWidthDeg:Float = 30.35
//let tileSpacing:Float = 1.1




class JFSCNNode : SCNNode {
    
    var nodesByCol:[[SCNNode]] = []
    var shapeRadius: Float = 0
    var currentPosition: Float = 0
    var currentAngle: Float = 0
    var sceneSize: CGSize
    var sceneSizeFactor: Float
    var circumsize:Float = 1
    
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
    
    override var rotation: SCNVector4 {
        didSet {
            self.currentAngle = self.rotation.w
        }
    }
    
    override init() {
        self.sceneSize = CGSize()
        self.sceneSizeFactor = 1
        super.init()
    }
    
    init(sceneSize:CGSize) {
        self.sceneSize = sceneSize
        self.sceneSizeFactor = (Float)(sceneSize.height / sceneSize.width * 1.35)
        super.init()
    }
    
//    init(geometry: SCNGeometry, sceneSize:CGSize) {
//        super.init()
//        self.geometry = geometry
//    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func generateTileNodes() {
        
        /*
        let tileWidth:CGFloat = 6
        let cylinderHeight:CGFloat = 66.0
        let tileRows:Int = 10
        let tileCols:Int = 6
        */
        // gap between tiles
        let tileGap = (cylinderHeight - (tileWidth * Float(tileRows))) / (Float(tileRows) - 1)
        // circumsize of cylinder
        self.circumsize = (tileWidth * Float(tileCols)) + (tileGap * (Float(tileCols) - 1))
        // cylinder radius
        self.shapeRadius = self.circumsize / (2 * Float(M_PI))
        // corner radius
        let cornerRadius = tileWidth / 10
        // angle between columns
        let tileAngleRad = Float(M_PI) * (2 / Float(tileCols))

        // generate tileMap
        var tileMap:[Int] = []
        for colId in 0...(tileCols - 1) {
            for rowId in 0...(tileRows - 1) {
                let tileId:Int = ((tileRows * colId) + rowId) / 2
                tileMap.append(tileId)
            }
        }
        let shuffledTileMap = shuffleList(tileMap)
        
        // shape
        let path = UIBezierPath(roundedRect: CGRect(x: CGFloat(tileWidth) / -2, y: CGFloat(tileWidth) / 2, width: CGFloat(tileWidth), height: CGFloat(tileWidth)), cornerRadius: CGFloat(cornerRadius))
        
        // calculation
        //let tileWidthRad = tileWidthDeg * (Float(M_PI) / 180)
        
        for colId in 0...(tileCols - 1) {
            
            self.nodesByCol.append([])
            
            let angle = tileAngleRad * Float(colId)
            let position = CGPoint(
                x: CGFloat(sin(angle)) * CGFloat(self.shapeRadius),
                y: CGFloat(cos(angle)) * CGFloat(self.shapeRadius))
            
            //println("radius:\(radius) angle:\(angle) x:\(position.x) y:\(position.y)")
            
            for rowId in 0...(tileRows - 1) {
                // creating tile
                let tile = SCNShape(path: path, extrusionDepth: 0.05)
                let tileNode = JFTileNode(x: colId, y: rowId, id: shuffledTileMap[((tileRows * colId) + rowId)], size:CGSize(width: CGFloat(tileWidth), height: CGFloat(tileWidth)), cornerRadius:CGFloat(cornerRadius))
                tileNode.position = SCNVector3(
                    x: Float(position.x),
                    y: ((Float(rowId) - (Float(tileRows - 1) / 2)) * (tileWidth + tileGap)),
                    //y: ((Float(rowId) * tileWidth) - (Float(tileRows - 1) / 2)) * tileGap,
                    z: Float(position.y))
                tileNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: angle)
                tileNode.baseAngle = angle
                
                self.addChildNode(tileNode)
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
        
        // get angle based on distance
        let deltaAngle = (Float)(translationX) * self.sceneSizeFactor * (Float)(M_PI) / 180.0
        let newAngle = self.currentAngle - deltaAngle
        //print("newAngle:\(newAngle) | currentAngle:\(self.currentAngle) | currentPosition:\(self.currentPosition) | shapeRadius:\(self.shapeRadius)")
        let rotateLayDown = SCNMatrix4MakeRotation(Float(M_PI) / 2, 1, 0, 0)
        let rotateRoll = SCNMatrix4MakeRotation(newAngle, 0, 0, 1)
        let rotate = SCNMatrix4Mult(rotateLayDown, rotateRoll)
        // get position based on distance
        let deltaPos = deltaAngle * self.shapeRadius
        let newPos = self.currentPosition + deltaPos
        let moveMatrix = SCNMatrix4MakeTranslation(newPos, self.position.y, 0)
        
        // hit right wall
        if((newPos > kWallDist) && (deltaPos > 0)) {
            return
        }
        //hit left wall
        if((newPos < -kWallDist) && (deltaPos < 0)) {
            return
        }
        // transform node
        self.transform = SCNMatrix4Mult(rotate, moveMatrix)
        
        self.currentAngle = newAngle
        self.currentPosition = newPos
    }
    
    func rollToRestingPosition(animated:Bool = true) {
        let tileAngle = (Float(M_PI) * 2) / Float(tileCols)
        let newAngle = round(self.currentAngle / tileAngle) * tileAngle
        let missingAngle = self.currentAngle - newAngle
        let rotateLayDown = SCNMatrix4MakeRotation(Float(M_PI) / 2, 1, 0, 0)
        let rotateRoll = SCNMatrix4MakeRotation(newAngle, 0, 0, 1)
        let rotate = SCNMatrix4Mult(rotateLayDown, rotateRoll)
        // get delta distance based on delta angle
        let missingDistance = missingAngle * self.shapeRadius
        let newPos = self.currentPosition + missingDistance
        //print("RTR newAngle:\(newAngle) | currentAngle:\(self.currentAngle) | currentPosition:\(self.currentPosition) | shapeRadius:\(self.shapeRadius)")
        let moveMatrix = SCNMatrix4MakeTranslation(newPos, self.position.y, 0)
        
        SCNTransaction.begin()
        if(animated) {
            SCNTransaction.setAnimationDuration(0.3)
        }
        self.transform = SCNMatrix4Mult(rotate, moveMatrix)
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.42, 0.0, 0.58, 1.0))
        SCNTransaction.setCompletionBlock({ () -> Void in
            self.currentAngle = newAngle
            self.currentPosition = newPos
        })
        SCNTransaction.commit()
    }
}


let blueColor = UIColor(red: 35/255, green: 153/255, blue: 218/255, alpha: 1)

enum JFTileNodeFaceType:Int {
    case root = 0
    case open = 1
    case closed
}

class JFTileNode: SCNNode {
    
    var turned:Bool = false {
        didSet {
            //if(turned != oldValue) {
            //    self.didTurn()
            //}
        }
    }
    var baseAngle:Float = 0
    var typeId:Int = 0
    var nodeId:CGPoint
    var tileNodes:[JFTileNodeFaceType:SCNNode] = [:]
    let explosionImage = UIImage(named: "explosion")
    
    //MARK: tmp
    var vanished:Bool = false
    var lock:Bool = false
    
    init(x:Int, y:Int, id:Int, size:CGSize, cornerRadius:CGFloat) {
        
        self.nodeId = CGPoint(x: x, y: y)
        self.typeId = id
        
        super.init()
        
        let path = UIBezierPath(roundedRect: CGRect(x: size.width / -2, y: size.height / -2, width: size.width, height: size.height), cornerRadius: cornerRadius)
        let tile = SCNShape(path: path, extrusionDepth: 0.05)
        self.geometry = tile
        self.addFaces(self, type: JFTileNodeFaceType.root)
        
        for faceType in [JFTileNodeFaceType.open, JFTileNodeFaceType.closed] {
            let tileShape = SCNShape(path: path, extrusionDepth: 0.05)
            let tileNode = SCNNode(geometry: tileShape)
            self.addFaces(tileNode, type: faceType)
            self.addChildNode(tileNode)
            self.tileNodes[faceType] = tileNode
        }
        
        self.adjustNodesVisibility()
    }
    
    required init?(coder aDecoder: NSCoder) {
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
            timing = 1 - (NSTimeInterval(targetAngleInt) - NSTimeInterval(rootAngleInt)) / NSTimeInterval(rotationAngleInt)
            
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
    
    func addFaces(node:SCNNode, type:JFTileNodeFaceType) {
        
        switch(type) {
        case .root:
            var materialFaces:[SCNMaterial] = Array()
            let face = SCNMaterial()
            face.diffuse.contents = UIImage(named: "tile0")
            materialFaces += [face]
            node.geometry?.materials = materialFaces
            break
        case .open:
            let tileId = (self.typeId % 10 + 1)
            let tileIdStr = (tileId < 10) ? "0\(tileId)" : String(tileId)
            
            var materialFaces:[SCNMaterial] = Array()
            let face = SCNMaterial()
            face.diffuse.contents = UIImage(named: "Karte\(tileIdStr)")
            materialFaces += [face]
            materialFaces += [face]
            let face3 = SCNMaterial()
            face3.diffuse.contents = UIImage(named: "tile100")
            //face3.reflective.contents = UIImage(named: "tileB")
            materialFaces += [face3]
            materialFaces += [face3]
            materialFaces += [face3]
            materialFaces += [face3]
            node.geometry?.materials = materialFaces
            break
        case .closed:
            var materialFaces:[SCNMaterial] = Array()
            let face = SCNMaterial()
            face.diffuse.contents = UIImage(named: "tile100")
            materialFaces += [face]
            materialFaces += [face]

            let face3 = SCNMaterial()
            face3.diffuse.contents = UIImage(named: "tile100")
            materialFaces += [face3]
            materialFaces += [face3]
            materialFaces += [face3]
            materialFaces += [face3]
            node.geometry?.materials = materialFaces
            break
        }
    }
    
    func isPairWithTile(tile:JFTileNode) -> Bool {
        return (self.typeId % 10) == (tile.typeId % 10)
    }
}