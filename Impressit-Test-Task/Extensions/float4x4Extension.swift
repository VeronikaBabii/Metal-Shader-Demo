//
//  float4x4Extension.swift
//  Impressit-Test-Task
//
//  Created by Veronika Babii on 17.10.2023.
//

import simd

extension float4x4 {
    
    init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
      let y = 1 / tan(fov * 0.5)
      let x = y / aspect
      let z = lhs ? far / (far - near) : far / (near - far)
      let X = SIMD4<Float>( x,  0,  0,  0)
      let Y = SIMD4<Float>( 0,  y,  0,  0)
      let Z = lhs ? SIMD4<Float>( 0,  0,  z, 1) : SIMD4<Float>( 0,  0,  z, -1)
      let W = lhs ? SIMD4<Float>( 0,  0,  z * -near,  0) : SIMD4<Float>( 0,  0,  z * near,  0)
      self.init()
      columns = (X, Y, Z, W)
    }

    init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
        self.init()
        columns = (
            [ 2 / (right - left), 0, 0, 0],
            [0, 2 / (top - bottom), 0, 0],
            [0, 0, 1 / (far - near), 0],
            [(left + right) / (left - right), (top + bottom) / (bottom - top), near / (near - far), 1]
        )
    }
    
    init(translation: SIMD3<Float>) {
      let matrix = float4x4(
        [            1,             0,             0, 0],
        [            0,             1,             0, 0],
        [            0,             0,             1, 0],
        [translation.x, translation.y, translation.z, 1]
      )
      self = matrix
    }
    
    init(rotationYXZ angle: SIMD3<Float>) {
      let rotationX = float4x4(rotationX: angle.x)
      let rotationY = float4x4(rotationY: angle.y)
      let rotationZ = float4x4(rotationZ: angle.z)
      self = rotationY * rotationX * rotationZ
    }
    
    init(rotationX angle: Float) {
      let matrix = float4x4(
        [1,           0,          0, 0],
        [0,  cos(angle), sin(angle), 0],
        [0, -sin(angle), cos(angle), 0],
        [0,           0,          0, 1]
      )
      self = matrix
    }

    init(rotationY angle: Float) {
      let matrix = float4x4(
        [cos(angle), 0, -sin(angle), 0],
        [         0, 1,           0, 0],
        [sin(angle), 0,  cos(angle), 0],
        [         0, 0,           0, 1]
      )
      self = matrix
    }

    init(rotationZ angle: Float) {
      let matrix = float4x4(
        [ cos(angle), sin(angle), 0, 0],
        [-sin(angle), cos(angle), 0, 0],
        [          0,          0, 1, 0],
        [          0,          0, 0, 1]
      )
      self = matrix
    }
}

extension Float {
  var degreesToRadians: Float {
    (self / 180) * Float.pi
  }
}
