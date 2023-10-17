//
//  MetalRenderer.swift
//  Impressit-Test-Task
//
//  Created by Veronika Babii on 17.10.2023.
//

import MetalKit
import RealityKit

class MetalRenderer: NSObject {
    
    // MARK: - Properties
    
    var device: MTLDevice
    var library: MTLLibrary!
    var pipelineDescriptor: MTLRenderPipelineDescriptor!
    var pipelineState: MTLRenderPipelineState?
    var samplerState: MTLSamplerState?
    
    var vertexBuffer: MTLBuffer?
    var texCoordBuffer: MTLBuffer?
    var normalBuffer: MTLBuffer?
    var vertexCount: Int?
    var indexBuffer: MTLBuffer?
    var indicesCount: Int?
    
    var pointVertices: [Vertex] = []
    
    var areEntitiesSetup = false
    var isModelPlaced = false
    
    var colorPixelFormat: MTLPixelFormat
    var depthStencilPixelFormat: MTLPixelFormat
    
    // MARK: - Lifecycle
    
    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat, depthStencilPixelFormat: MTLPixelFormat) {
        self.device = device
        self.colorPixelFormat = colorPixelFormat
        self.depthStencilPixelFormat = depthStencilPixelFormat
        super.init()
        setupMetal()
    }
    
    // MARK: - Methods
    
    private func setupMetal() {
        library = device.makeDefaultLibrary()
        pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
        
        // Placeholder triangle to render and apply light shader to.
        pointVertices = [
            Vertex(position: vector_float3(-0.5, -0.5, 0), texCoord: vector_float2(), normal: vector_float3(),color: vector_float4(1, 0, 0, 1)), // red
            Vertex(position: vector_float3(0.5, -0.5, 0), texCoord: vector_float2(), normal: vector_float3(), color: vector_float4(0, 1, 0, 1)), // green
            Vertex(position: vector_float3(-0.5, 0.5, 0), texCoord: vector_float2(), normal: vector_float3(), color: vector_float4(0, 0, 1, 1)), // blue
        ]
        
        setupPipelineDescriptor()
    }
    
    private func setupPipelineDescriptor() {
        guard let vertexFunction = library.makeFunction(name: "customVertexShader"),
              let fragmentFunction = library.makeFunction(name: "customFragmentShader") else {
            print("setupPipelineDescriptor: Enable to find shaders.")
            return
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        
        let vertexDescriptor = setupVertexDescriptor()
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("setupPipelineDescriptor: Error creating pipeline state: \(error)")
        }
    }
    
    private func setupVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        // Texture coordinates.
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        // Normals.
        vertexDescriptor.attributes[2].format = .float3
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        // Color.
        vertexDescriptor.attributes[3].format = .float4
        vertexDescriptor.attributes[3].offset = MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[3].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride

        return vertexDescriptor
    }
    
    private func getTransformationMatrices() -> (projectionMatrix: float4x4, viewMatrix: float4x4) {
        let aspect: Float = 1.0
        let fov = Float(70).degreesToRadians
        let near: Float = 0.1
        let far: Float = 100
        let target: SIMD3<Float> = [0, 0, 0]
        let rotation: SIMD3<Float> = [0, 0, 0]
        
        let projectionMatrix = float4x4(projectionFov: fov, near: near, far: far, aspect: aspect)
        let viewMatrix = (float4x4(translation: target) * float4x4(rotationYXZ: rotation)).inverse
        
        return (projectionMatrix, viewMatrix)
    }
    
    func prepareModelEntity() -> Entity? {
        if isModelPlaced {
            print("addModel: Model is already placed in the scene.")
            return nil
        }
        
        guard let modelWithData = ModelManager.shared.getModelWithData(named: ModelConfig.sofaChairModel) else {
            print("addModel: Error getting model entity.")
            return nil
        }
        let modelEntity = modelWithData.entity
        let vertexData = modelWithData.vertexData
        
        let positionBufferLength = vertexData.positions.count * MemoryLayout<SIMD4<Float>>.stride
        let texCoordBufferLength = vertexData.texCoords.count * MemoryLayout<SIMD2<Float>>.stride
        let normalBufferLength = vertexData.normals.count * MemoryLayout<SIMD3<Float>>.stride
        
        if let positionBuffer = device.makeBuffer(bytes: vertexData.positions, length: positionBufferLength, options: []),
           let texCoordBuffer = device.makeBuffer(bytes: vertexData.texCoords, length: texCoordBufferLength, options: []),
           let normalBuffer = device.makeBuffer(bytes: vertexData.normals, length: normalBufferLength, options: []) {
            
            let vertexCount = vertexData.positions.count
            
            self.vertexBuffer = positionBuffer
            self.texCoordBuffer = texCoordBuffer
            self.normalBuffer = normalBuffer
            self.vertexCount = vertexCount
        }
        
        areEntitiesSetup = true
        isModelPlaced = true
        
        return(modelEntity)
    }
}

// MARK: - MTKViewDelegate

extension MetalRenderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func draw(in view: MTKView) {
        renderFrame(view)
    }
    
    private func renderFrame(_ view: MTKView) {
        guard areEntitiesSetup else { return }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else {
            print("renderFrame: Error getting view's objects.")
            return
        }
        
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        
        guard let pipelineState = pipelineState,
              let commandQueue = device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            print("renderFrame: Error preparing Metal objects.")
            return
        }
                
        // Set up depthStencilState.
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {
            print("renderFrame:: Error creating depthStencilState")
            return
        }
        renderEncoder.setDepthStencilState(depthStencilState)
        
        // Set uniforms buffer with transformation matrices.
        let matrices = self.getTransformationMatrices()
        var uniforms = Uniforms(viewMatrix: matrices.viewMatrix, projectionMatrix: matrices.projectionMatrix)
        let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.stride, options: [])
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        // Set light buffer for fragment shader.
        var light = Light(position: [0, 0, 0], color: [1, 1, 1], intensity: 10.0)
        let lightBuffer = device.makeBuffer(bytes: &light, length: MemoryLayout<Light>.stride, options: [])
        renderEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: 0)
        
        // Set buffers for vertex shader.
        let vertexBuffer = device.makeBuffer(bytes: pointVertices, length: pointVertices.count * MemoryLayout<Vertex>.stride, options: [])
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(normalBuffer, offset: 0, index: 2)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setCullMode(.none)
        
        // Draw.
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: pointVertices.count)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
