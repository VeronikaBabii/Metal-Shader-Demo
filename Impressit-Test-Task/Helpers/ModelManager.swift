//
//  ModelManager.swift
//  Impressit-Test-Task
//
//  Created by Veronika Babii on 17.10.2023.
//

import RealityKit

class ModelManager {
    
    static let shared = ModelManager()
    
    func getModelWithData(named modelName: String) -> ModelWithData? {
        
        guard let modelEntity = try? Entity.load(named: modelName) else {
            print("getModelVertexData: Error loading or setting up model: \(modelName)")
            return nil
        }
        
        guard let vertexData = self.extractVertexData(from: modelEntity) else {
            print("getModelVertexData: Error getting vertexData from modelEntity")
            return nil
        }
        
        let scalingFactor: Float = 0.005
        modelEntity.transform.scale = SIMD3<Float>(scalingFactor, scalingFactor, scalingFactor)
        
        return ModelWithData(entity: modelEntity, vertexData: vertexData)
    }
    
    private func extractVertexData(from modelEntity: Entity) -> VertexData? {
        guard let entity = modelEntity.children[0] as? ModelEntity,
              let meshComponent = entity.components[ModelComponent.self] as? ModelComponent else {
            print("extractVertexData: Error getting entity or meshComponent")
            return nil
        }
        
        let meshModels = meshComponent.mesh.contents.models
        
        var positions: [SIMD4<Float>] = []
        var texCoords: [SIMD2<Float>] = []
        var normals: [SIMD3<Float>] = []

        for meshModel in meshModels {
            let meshModelParts = meshModel.parts

            for meshModelPart in meshModelParts {

                if let localNormals = meshModelPart.normals,
                   let localTextureCoordinates = meshModelPart.textureCoordinates {

                    let localPositions = meshModelPart.positions
                    let localPositions4D = localPositions.map { SIMD4($0.x, $0.y, $0.z, 1.0) }
                    positions.append(contentsOf: localPositions4D)

                    texCoords.append(contentsOf: localTextureCoordinates)
                    normals.append(contentsOf: localNormals)
                }
            }
        }
        
        return VertexData(positions: positions, texCoords: texCoords, normals: normals)
    }
}
