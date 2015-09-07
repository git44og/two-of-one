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
                let tileNode = JFTileNode()
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
            materialFaces += [face]
            let face2 = SCNMaterial()
            face2.diffuse.contents = UIImage(named: "tile50")
            materialFaces += [face2]
            let face3 = SCNMaterial()
            face3.diffuse.contents = UIImage(named: "tile100")
            materialFaces += [face3]
            materialFaces += [face3]
            materialFaces += [face3]
            materialFaces += [face3]
        }
        node.geometry?.materials = materialFaces
    }
}

class JFTileNode: SCNNode {
    
    var turned:Bool = false {
        didSet {
            if(turned != oldValue) {
                self.didTurn()
            }
        }
    }
    
    var baseAngle:Float = 0
    
    override init() {
        
        super.init()
        
        let path = UIBezierPath(roundedRect: CGRect(x: -0.5, y: -0.5, width: 1.0, height: 1.0), cornerRadius: 0.1)
        let tile = SCNShape(path: path, extrusionDepth: 0.05)
        self.geometry = tile
        self.addFaces()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func flip() {
        self.turned = !self.turned
    }
    
    func didTurn() {
        
        let oldAngle = self.rotation.w
        var newAngle:Float = self.turned ? baseAngle + Float(M_PI) : baseAngle
        let currentPos = self.position
        
        let rotateMatrix = SCNMatrix4MakeRotation(newAngle, 0, 1, 0)
        let moveMatrix = SCNMatrix4MakeTranslation(currentPos.x, currentPos.y, currentPos.z)
        
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(0.3)
        
        self.transform = SCNMatrix4Mult(rotateMatrix, moveMatrix)
        
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.42, 0.0, 0.58, 1.0))
        SCNTransaction.setCompletionBlock({ () -> Void in
            println(">> after:\(self.rotation.w)")
            /*
            var newAngle = self.rotation.w
            if(self.rotation.w > Float(M_PI) * 2) {
                newAngle = self.rotation.w - Float(M_PI) * 2
            } else if(self.rotation.w < Float(M_PI) * -2) {
                newAngle = self.rotation.w + Float(M_PI) * 2
            }
            println(">> old:\(self.rotation.w) new:\(newAngle)")
            let rotateMatrix = SCNMatrix4MakeRotation(newAngle, 0, 1, 0)
            let moveMatrix = SCNMatrix4MakeTranslation(currentPos.x, currentPos.y, currentPos.z)
            self.transform = SCNMatrix4Mult(rotateMatrix, moveMatrix)
            */
        })
        SCNTransaction.commit()

    }

    func addFaces() {
        
        let tileId = JFrand(10) + 1
        var tileIdStr = (tileId < 10) ? "0\(tileId)" : String(tileId)

        var materialFaces:[SCNMaterial] = Array()
        let face = SCNMaterial()
        face.diffuse.contents = UIImage(named: "Karte\(tileIdStr)")
        materialFaces += [face]
        let face2 = SCNMaterial()
        face2.diffuse.contents = UIImage(named: "tile50")
        materialFaces += [face2]
        let face3 = SCNMaterial()
        face3.diffuse.contents = UIImage(named: "tile100")
        materialFaces += [face3]
        materialFaces += [face3]
        materialFaces += [face3]
        materialFaces += [face3]
        self.geometry?.materials = materialFaces
    }
}