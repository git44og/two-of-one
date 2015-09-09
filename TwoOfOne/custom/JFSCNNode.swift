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
rotate y^2+x^2 = r^2

50px^2+?^2=r^2

sin = gegnkathete / hypo
sin(a) = z / radius
cos = ankathete / hypo
tan = gegen / an


alpha = 30.35
gegen = 50
1) gegen/atan(30.35) = radius

2) x-y
hyp=radius
x=asin/hypo
yacos/hypo
*/



// config
let tileWidth:CGFloat = 1
let tileWidthDeg:Float = 30.35
let tileNum:Int = 10
let tileRows:Int = 6
let tileSpacing:Float = 1.1



class JFSCNNode : SCNNode {
    
    var nodesByCol:[[SCNNode]] = []
    
    override var transform: SCNMatrix4 {
        didSet {
            //// slow on device
            self.adjustTransparency()
        }
    }
    
    override init() {
        super.init()
    }
    
    init(geometry: SCNGeometry) {
        super.init()
        self.geometry = geometry
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func generateTileNodes() {
        
        // shape
        let path = UIBezierPath(roundedRect: CGRect(x: tileWidth / -2, y: tileWidth / 2, width: tileWidth, height: tileWidth), cornerRadius: 0.1)
        
        // calculation
        let tileWidthRad = tileWidthDeg * (Float(M_PI) / 180)
        let tileAngleRad = Float(M_PI) * (2 / Float(tileNum))
        let radius = Float(tileWidth) / tan(tileWidthRad)

        //for colId in 0...5 {
        for colId in 0...(tileNum - 1) {
            
            self.nodesByCol.append([])
            
            let angle = tileAngleRad * Float(colId)
            let position = CGPoint(
                x: CGFloat(sin(angle)) * CGFloat(radius),
                y: CGFloat(cos(angle)) * CGFloat(radius))
            
            //println("radius:\(radius) angle:\(angle) x:\(position.x) y:\(position.y)")
            
            //for rowId in 3...3 {
            for rowId in 0...(tileRows - 1) {
                // creating tile
                let tile = SCNShape(path: path, extrusionDepth: 0.05)
                let tileNode = JFTileNode(x: colId, y: rowId)
                tileNode.position = SCNVector3(
                    x: Float(position.x),
                    y: (Float(rowId) - (Float(tileRows - 1) / 2)) * tileSpacing,
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
    }
    
    
    //MARK: deprecated
    func checkAngle() {
        
        let angleIntPerQuarter = (self.rotation.w / Float(M_PI)) * (Float(tileNum) / 2) // 45deg == 1 | 90deg == 2
        println("angle \(self.rotation.w) | \(angleIntPerQuarter) y:\(self.rotation.y)")
        
        var angleId = Int(round(angleIntPerQuarter))
        if(self.rotation.y > 0) {
            angleId = angleId * -1 + 8
        }
        if(abs(angleIntPerQuarter - round(angleIntPerQuarter)) < 0.1) {
            //println("angleId \(angleId) [\(angleIntPerQuarter)]")
            for col in 0...7 {
                for node in self.nodesByCol[col] {
                    self.nodeActive(node, active: (col == angleId))
                }
            }
        } else {
            for col in 0...7 {
                for node in self.nodesByCol[col] {
                    self.nodeActive(node, active: false)
                }
            }
        }
    }
    
    func nodeActive(node:SCNNode, active:Bool) {
        var materialFaces:[SCNMaterial] = Array()
        
        let tileId = JFrand(35) + 1
        var tileIdStr = (tileId < 10) ? "0\(tileId)" : String(tileId)
        
        for i in 0...0 {
            let face = SCNMaterial()
            face.diffuse.contents = active ? UIImage(named: "tile100") : UIImage(named: "Karte\(tileIdStr)")
            face.shininess = 0
            face.specular.contents = UIImage(named: "tileA")
            //face.emission.contents = UIImage(named: "tileA")
            materialFaces += [face]
            let face2 = SCNMaterial()
            face2.diffuse.contents = UIImage(named: "tileA")
            materialFaces += [face2]
            let face3 = SCNMaterial()
            face3.diffuse.contents = UIImage(named: "tileA")
            materialFaces += [face3]
            materialFaces += [face3]
            materialFaces += [face3]
            materialFaces += [face3]
        }
        node.geometry?.materials = materialFaces
    }
}

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
    
    init(x:Int, y:Int) {
        
        self.nodeId = CGPoint(x: x, y: y)
        
        super.init()
        
        let path = UIBezierPath(roundedRect: CGRect(x: -0.5, y: -0.5, width: 1.0, height: 1.0), cornerRadius: 0.1)
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
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func flip(animated:Bool = true) {
        self.turned = !self.turned
        if(animated) {
            self.didTurn()
        }
    }
    
    func adjustNodesVisibility() {
        self.tileNodes[JFTileNodeFaceType.open]?.opacity = self.turned ? 1.0 : 0.0
        self.tileNodes[JFTileNodeFaceType.closed]?.opacity = self.turned ? 0.0 : 1.0
    }
    
    func didTurn() {
        
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
            
            // get 0.5 or 1.5
            // root = [0,2[
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
            
            1.4 -> 1.9 > ceil > 2 > 1.5
            1.4 -> 1.9 > floor > 1 > 0.5
            0.9 -> 1.4 > ceil > 2 > 1.5
            0.9 -> 1.4 > floor > 1 > 0.5
            0.0 -> 0.5 > ceil > 1 > 0.5
            0.0 -> 0.5 > floor > 0 > -0.5
            2.0 -> 2.5 > ceil > 3 > 2.5
            2.0 -> 2.5 > floor > 2 > 1.5
            */
            
            //println("rootAngle:\(rootAngleInt) timing:\(timing) tmp1:\(targetAngleInt)")
        }
        
        // run aminations
        let rotationAction = SCNAction.rotateByAngle(rotationAngle, aroundAxis: SCNVector3(x: 0, y: 1, z: 0), duration: rotationDuration)
        rotationAction.timingMode = SCNActionTimingMode.Linear
        self.runAction(rotationAction)
        
        let nodeToHide = self.turned ? self.tileNodes[JFTileNodeFaceType.closed] : self.tileNodes[JFTileNodeFaceType.open]
        nodeToHide?.runAction(SCNAction.sequence([
            SCNAction.waitForDuration(rotationDuration * timing),
            SCNAction.fadeOutWithDuration(0)]))
        
        let nodeToShow = self.turned ? self.tileNodes[JFTileNodeFaceType.open] : self.tileNodes[JFTileNodeFaceType.closed]
        nodeToShow?.runAction(SCNAction.sequence([
            SCNAction.waitForDuration(rotationDuration * timing),
            SCNAction.fadeInWithDuration(0)]))
        
        /*
        let oldAngle = self.rotation.w
        var newAngle:Float = self.turned ? baseAngle + Float(M_PI) : baseAngle
        let currentPos = self.position
        
        let rotateMatrix = SCNMatrix4MakeRotation(newAngle, 0, 1, 0)
        let moveMatrix = SCNMatrix4MakeTranslation(currentPos.x, currentPos.y, currentPos.z)
        
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(0.15)
        SCNTransaction.setCompletionBlock({ () -> Void in
            self.adjustNodesVisibility()
        })
        SCNTransaction.commit()
        
        
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(0.3)
        self.transform = SCNMatrix4Mult(rotateMatrix, moveMatrix)
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.42, 0.0, 0.58, 1.0))
        SCNTransaction.setCompletionBlock({ () -> Void in
        })
        
        SCNTransaction.commit()
        */
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
            let tileId = JFrand(10) + 1
            var tileIdStr = (tileId < 10) ? "0\(tileId)" : String(tileId)
            
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
            face.diffuse.contents = UIImage(named: "tile50")
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
}