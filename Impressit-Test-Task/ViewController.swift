//
//  ViewController.swift
//  Impressit-Test-Task
//
//  Created by Veronika Babii on 17.10.2023.
//

import MetalKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    var arView: ARView!
    var metalView: MTKView!
    var metalRenderer: MetalRenderer!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: - Methods

    private func setupViews() {
        setupArView()
        setupMetalView()
        setupArSession()
    }
    
    private func setupArView() {
        arView = ARView(frame: view.bounds)
        arView.isUserInteractionEnabled = true
        arView.backgroundColor = .clear
        arView.session.delegate = self
        view.addSubview(arView)
    }
    
    private func setupMetalView() {
        metalView = MTKView(frame: view.bounds)
        
        let device = MTLCreateSystemDefaultDevice()!
        metalView.device = device
        
        let depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        let colorPixelFormat = MTLPixelFormat.bgra8Unorm
        metalRenderer = MetalRenderer(device: device,
                                      colorPixelFormat: colorPixelFormat,
                                      depthStencilPixelFormat: depthStencilPixelFormat)
        metalView.delegate = metalRenderer
        metalView.colorPixelFormat = colorPixelFormat
        metalView.depthStencilPixelFormat = depthStencilPixelFormat
        metalView.isOpaque = false
        metalView.backgroundColor = .clear
        metalView.sampleCount = 1
        metalView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.addSubview(metalView)
    }
    
    private func setupArSession() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
    }
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                let anchorEntity = AnchorEntity(anchor: planeAnchor)
                if let modelEntity = metalRenderer.prepareModelEntity() {
                    anchorEntity.addChild(modelEntity)
                    arView.scene.addAnchor(anchorEntity)
                    print("Model placed.")
                }
            }
        }
    }
}
