//
//  ShapeType.swift
//  GFighter
//
//  Created by Santo Gaglione on 20/02/22.
//

import Foundation
import SceneKit

public enum ShapeType:Int {
    
    case Box = 0
    case Sphere
    case Pyramyd
    case Torus
    case Capsule
    case Cylinder
    case Cone
    case Tube
    

static func random() -> ShapeType {
    let maxValue = Tube.rawValue
    let rand = arc4random_uniform(UInt32(maxValue+1))
    return ShapeType(rawValue: Int(rand))!
    
  }
}
