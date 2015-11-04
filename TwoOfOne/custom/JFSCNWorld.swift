//
//  JFSCNWorld.swift
//  TwoOfOne
//
//  Created by Jens Fischer on 03/11/15.
//  Copyright © 2015 Jens. All rights reserved.
//

import Foundation
import SceneKit


let kWallBackTileColor = UIColor(red: 203/255, green: 255/255, blue: 240/255, alpha: 0.5)
let kWallBackTileColorTransparency = UIColor(white: 1, alpha: 1.0)
let kWallSideTileColor = UIColor(white: 1, alpha: 0.49)
let kWallSideTileColorTransparency = UIColor(white: 1, alpha: 1)


enum JFWallTileType:Int {
    case back = 0
    case side = 1
}

struct JFGridIndex {
    var x: Int
    var y: Int
}

struct JFGridSize {
    var width: Int
    var height: Int
}


class JFSCNWorld : SCNNode {
    
    override init() {
        super.init()
        
        let backWall = JFSCNWall(size: JFGridSize(width: tileCols + 2, height: tileRows), type: JFWallTileType.back)
        backWall.position = SCNVector3Make(0, 0, -kDistanceWall - kDistanceCamera)
        self.addChildNode(backWall)
        
        let leftWall = JFSCNWall(size: JFGridSize(width: tileCols, height: tileRows), type: JFWallTileType.side)
        let leftWallMove = SCNMatrix4MakeTranslation(-backWall.width / 2, 0, -kDistanceWall - kDistanceCamera + (leftWall.width / 2))
        let leftWallRotate = SCNMatrix4MakeRotation(Float(M_PI_2), 0, 1, 0)
        leftWall.transform = SCNMatrix4Mult(leftWallRotate, leftWallMove)
        self.addChildNode(leftWall)

        let rightWall = JFSCNWall(size: JFGridSize(width: tileCols, height: tileRows), type: JFWallTileType.side)
        let rightWallMove = SCNMatrix4MakeTranslation(backWall.width / 2, 0, -kDistanceWall - kDistanceCamera + (rightWall.width / 2))
        let rightWallRotate = SCNMatrix4MakeRotation(-Float(M_PI_2), 0, 1, 0)
        rightWall.transform = SCNMatrix4Mult(rightWallRotate, rightWallMove)
        self.addChildNode(rightWall)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


class JFSCNWall : SCNNode {
    
    var width:Float = 1
    
    init(size:JFGridSize, type:JFWallTileType) {
        
        super.init()

        self.setupTiles(size, type: type)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTiles(size:JFGridSize, type:JFWallTileType) {
        
        let tileGap = (cylinderHeight - (tileWidth * Float(tileRows))) / (Float(tileRows) - 1)
        
        for x in 0 ... (size.width - 1) {
            for y in 0 ... (size.height - 1) {
                let tile = JFSCNWallTile(size: CGSize(width: CGFloat(tileWidth), height: CGFloat(tileWidth)), type: JFWallTileType.back)
                tile.position = SCNVector3Make(
                    (Float(tileWidth) + tileGap) * (Float(x) - ((Float(size.width) - 1) / 2)),
                    (Float(tileWidth) + tileGap)  * (Float(y) - ((Float(size.height) - 1) / 2)),
                    0)
                self.addChildNode(tile)
            }
        }
        
        self.width = (Float(tileWidth) * Float(size.width)) + (tileGap * (Float(size.width) - 0))
    }
}

class JFSCNWallTile : SCNNode {
    
    init(size:CGSize, type:JFWallTileType) {
        
        super.init()
        
        let extrusionDepth = size.width * kTileExtrusion
        
        // open tile
        let tileBaseShape = SCNBox(width: size.width, height: size.height, length: extrusionDepth, chamferRadius: 0)
        tileBaseShape.firstMaterial?.diffuse.contents = UIColor.clearColor()
        self.geometry = tileBaseShape
        
        // add visible nodes
        self.addShapeFace(size, type:type)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addShapeFace(size:CGSize, type:JFWallTileType) {
        
        let cornerRadius = size.width * kTileCornerradius
        let extrusionDepth = size.width * kTileExtrusion
        
        let path = UIBezierPath(roundedRect: CGRect(x: size.width / -2, y: size.height / -2, width: size.width, height: size.height), cornerRadius: cornerRadius)
        let tileShape = SCNShape(path: path, extrusionDepth: extrusionDepth)
        
        switch(type) {
        case .back:
            tileShape.firstMaterial?.diffuse.contents = kWallBackTileColor
            tileShape.firstMaterial?.diffuse.intensity = 0.52
            tileShape.firstMaterial?.transparent.contents = kWallBackTileColorTransparency
            tileShape.firstMaterial?.transparent.intensity = 0.07
            break
        case .side:
            tileShape.firstMaterial?.diffuse.contents = kWallSideTileColor
            tileShape.firstMaterial?.diffuse.intensity = 0.52
            tileShape.firstMaterial?.transparent.contents = kWallSideTileColorTransparency
            tileShape.firstMaterial?.transparent.intensity = 0.07
            break
        }
        self.geometry = tileShape
    }
}