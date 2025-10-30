//
//  ContentView.swift
//  ARKITDemo
//
//  Created by EK_Macmini_33 on 18/09/2025.
//

import SwiftUI
import ARKit
import SceneKit

enum ObjectType: CaseIterable {
    case cube, sphere, pyramid, cylinder
    
    var name: String {
        switch self {
        case .cube: return "Cube"
        case .sphere: return "Sphere" 
        case .pyramid: return "Pyramid"
        case .cylinder: return "Cylinder"
        }
    }
    
    var icon: String {
        switch self {
        case .cube: return "cube"
        case .sphere: return "circle"
        case .pyramid: return "triangle"
        case .cylinder: return "cylinder"
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        print("🚀 Creating ARSCNView...")
        let arView = ARSCNView(frame: .zero)
        let coordinator = context.coordinator
        
        // Setup AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        print("🎥 Starting AR session...")
        arView.session.run(configuration)
        
        // Setup scene
        arView.delegate = coordinator
        arView.scene.rootNode.addChildNode(coordinator.lightsNode)
        
        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTap(_:)))
        let panGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
        
        arView.addGestureRecognizer(tapGesture)
        arView.addGestureRecognizer(panGesture)
        arView.addGestureRecognizer(pinchGesture)
        
        coordinator.arView = arView
        
        // Setup notifications
        NotificationCenter.default.addObserver(coordinator, 
                                             selector: #selector(Coordinator.selectObject(_:)), 
                                             name: NSNotification.Name("SelectObject"), 
                                             object: nil)
        NotificationCenter.default.addObserver(coordinator, 
                                             selector: #selector(Coordinator.resetAR), 
                                             name: NSNotification.Name("ResetAR"), 
                                             object: nil)
        
        print("✅ ARSCNView setup complete")
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Updates can be handled here if needed
    }
    
    func makeCoordinator() -> Coordinator {
        print("👷 Creating Coordinator...")
        return Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var arView: ARSCNView?
        var selectedObjectType: ObjectType = .cube
        var selectedColor: UIColor = .red
        var selectedNode: SCNNode?
        var planesDetected: [ARPlaneAnchor: SCNNode] = [:]
        
        let lightsNode: SCNNode = {
            let lightNode = SCNNode()
            let light = SCNLight()
            light.type = .omni
            light.intensity = 1000
            lightNode.light = light
            lightNode.position = SCNVector3(0, 10, 0)
            return lightNode
        }()
        
        @objc func selectObject(_ notification: Notification) {
            guard let data = notification.object as? [String: Any],
                  let type = data["type"] as? ObjectType,
                  let color = data["color"] as? Color else { return }
            
            selectedObjectType = type
            selectedColor = UIColor(color)
            
            // Visual feedback that object was selected
            print("Selected: \(type.name) in \(color)")
        }
        
        @objc func resetAR() {
            arView?.scene.rootNode.childNodes.forEach { node in
                if node != lightsNode && !planesDetected.values.contains(node) {
                    node.removeFromParentNode()
                }
            }
            print("AR Scene cleared")
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            
            // First, always check if we're tapping an existing object
            let hitResults = arView.hitTest(location, options: [:])
            if let hitResult = hitResults.first, !(hitResult.node.name?.contains("plane") == true) {
                // Tapped an existing object - select it for dragging
                selectedNode = hitResult.node
                highlightNode(selectedNode!)
                print("Selected object for dragging")
                
                // Provide haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                return
            }
            
            // If no object was tapped, handle placement
            handlePlacement(at: location)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            
            switch gesture.state {
            case .began:
                // If no object is selected, try to select one at the pan start location
                if selectedNode == nil {
                    let hitResults = arView.hitTest(location, options: [:])
                    if let hitResult = hitResults.first, !(hitResult.node.name?.contains("plane") == true) {
                        selectedNode = hitResult.node
                        highlightNode(selectedNode!)
                        print("Selected object during pan")
                    } else {
                        return // No object to drag
                    }
                }
                
                // Make object kinematic for smooth dragging
                selectedNode?.physicsBody?.type = .kinematic
                
            case .changed:
                guard let selectedNode = selectedNode else { return }
                
                // Try multiple hit test methods for smooth dragging
                var worldPosition: SCNVector3?
                
                // Method 1: Plane hit test
                let planeHitResults = arView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
                if let hitResult = planeHitResults.first {
                    worldPosition = SCNVector3(
                        hitResult.worldTransform.columns.3.x,
                        hitResult.worldTransform.columns.3.y + 0.1,
                        hitResult.worldTransform.columns.3.z
                    )
                }
                
                // Method 2: Feature points if no plane
                if worldPosition == nil {
                    let featureHitResults = arView.hitTest(location, types: [.featurePoint])
                    if let hitResult = featureHitResults.first {
                        worldPosition = SCNVector3(
                            hitResult.worldTransform.columns.3.x,
                            hitResult.worldTransform.columns.3.y + 0.1,
                            hitResult.worldTransform.columns.3.z
                        )
                    }
                }
                
                // Method 3: Keep same Y level as object
                if worldPosition == nil {
                    if let currentFrame = arView.session.currentFrame {
                        let transform = currentFrame.camera.transform
                        worldPosition = SCNVector3(
                            transform.columns.3.x,
                            selectedNode.position.y, // Keep same Y
                            transform.columns.3.z - 1.0
                        )
                    }
                }
                
                // Apply position with smooth animation
                if let position = worldPosition {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.1
                    selectedNode.position = position
                    SCNTransaction.commit()
                }
                
            case .ended, .cancelled:
                guard let selectedNode = selectedNode else { return }
                
                // Make object static again
                selectedNode.physicsBody?.type = .static
                
                // Keep object selected with visual feedback for a moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.removeHighlight(selectedNode)
                    self.selectedNode = nil
                }
                
                // Provide completion haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let selectedNode = selectedNode else { return }
            
            switch gesture.state {
            case .changed:
                let scale = Float(gesture.scale)
                let currentScale = selectedNode.scale
                let newScale = SCNVector3(
                    currentScale.x * scale,
                    currentScale.y * scale,
                    currentScale.z * scale
                )
                
                // Limit scale to reasonable bounds
                let clampedScale = SCNVector3(
                    max(0.1, min(5.0, newScale.x)),
                    max(0.1, min(5.0, newScale.y)),
                    max(0.1, min(5.0, newScale.z))
                )
                
                selectedNode.scale = clampedScale
                gesture.scale = 1.0
            case .ended:
                removeHighlight(selectedNode)
                self.selectedNode = nil
            default:
                break
            }
        }
        
        func handlePlacement(at location: CGPoint) {
            guard let arView = arView else { return }
            
            // Enhanced placement logic with multiple fallback methods
            var worldPosition: SCNVector3?
            
            // Method 1: Try plane hit test
            let planeHitResults = arView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
            if let hitResult = planeHitResults.first {
                worldPosition = SCNVector3(
                    hitResult.worldTransform.columns.3.x,
                    hitResult.worldTransform.columns.3.y,
                    hitResult.worldTransform.columns.3.z
                )
            }
            
            // Method 2: Feature points
            if worldPosition == nil {
                let featureHitResults = arView.hitTest(location, types: [.featurePoint])
                if let hitResult = featureHitResults.first {
                    worldPosition = SCNVector3(
                        hitResult.worldTransform.columns.3.x,
                        hitResult.worldTransform.columns.3.y,
                        hitResult.worldTransform.columns.3.z
                    )
                }
            }
            
            // Method 3: Camera-relative placement
            if worldPosition == nil {
                if let currentFrame = arView.session.currentFrame {
                    let transform = currentFrame.camera.transform
                    worldPosition = SCNVector3(
                        transform.columns.3.x,
                        transform.columns.3.y - 0.5,
                        transform.columns.3.z - 1.0
                    )
                }
            }
            
            if let position = worldPosition {
                addObject(at: position)
            }
        }

        func addObject(at position: SCNVector3) {
            let geometry = createGeometry(for: selectedObjectType)
            let material = SCNMaterial()
            material.diffuse.contents = selectedColor
            material.specular.contents = UIColor.white
            material.shininess = 0.8
            geometry.materials = [material]
            
            let node = SCNNode(geometry: geometry)
            node.position = SCNVector3(position.x, position.y + 0.1, position.z)
            
            // Add a name to identify this as a user-created object
            node.name = "userObject_\(selectedObjectType.name)"
            
            let baseScale: Float = 0.3
            node.scale = SCNVector3(baseScale, baseScale, baseScale)
            
            // Use static physics body
            let shape = SCNPhysicsShape(geometry: geometry, options: nil)
            node.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
            
            // Add gentle rotation animation
            let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 6)
            let repeatRotation = SCNAction.repeatForever(rotation)
            node.runAction(repeatRotation)
            
            arView?.scene.rootNode.addChildNode(node)
            
            // Enhanced haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            print("Added \(selectedObjectType.name) at position: \(node.position)")
        }
        
        func createGeometry(for type: ObjectType) -> SCNGeometry {
            switch type {
            case .cube:
                return SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0.02)
            case .sphere:
                return SCNSphere(radius: 0.1)
            case .pyramid:
                return SCNPyramid(width: 0.2, height: 0.24, length: 0.2)
            case .cylinder:
                return SCNCylinder(radius: 0.1, height: 0.2)
            }
        }
        
        func highlightNode(_ node: SCNNode) {
            // Remove any existing highlight first
            removeHighlight(node)
            
            // Scale animation for selection feedback
            let highlightAction = SCNAction.sequence([
                SCNAction.scale(to: 1.1, duration: 0.15),
                SCNAction.scale(to: 1.05, duration: 0.1)
            ])
            node.runAction(highlightAction, forKey: "highlight")
            
            // Add glow effect
            node.geometry?.materials.forEach { material in
                material.emission.contents = UIColor.cyan.withAlphaComponent(0.4)
            }
            
            // Add subtle pulsing glow animation
            let pulseAction = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.7, duration: 0.8),
                SCNAction.fadeOpacity(to: 1.0, duration: 0.8)
            ])
            let pulseForever = SCNAction.repeatForever(pulseAction)
            node.runAction(pulseForever, forKey: "pulse")
            
            print("Object highlighted and ready for dragging")
        }
        
        func removeHighlight(_ node: SCNNode) {
            // Remove highlight animations
            node.removeAction(forKey: "highlight")
            node.removeAction(forKey: "pulse")
            
            // Reset scale smoothly
            let resetScale = SCNAction.scale(to: 1.0, duration: 0.2)
            node.runAction(resetScale)
            
            // Remove glow effect
            node.geometry?.materials.forEach { material in
                material.emission.contents = UIColor.black
            }
            
            print("Object highlight removed")
        }
        
        // MARK: - ARSCNViewDelegate
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), 
                                       height: CGFloat(planeAnchor.extent.z))
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
            planeGeometry.materials = [material]
            
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            
            node.addChildNode(planeNode)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                  let planeNode = node.childNodes.first,
                  let plane = planeNode.geometry as? SCNPlane else { return }
            
            plane.width = CGFloat(planeAnchor.extent.x)
            plane.height = CGFloat(planeAnchor.extent.z)
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        }
    }
}

struct ObjectButton: View {
    let type: ObjectType
    let color: Color
    
    var body: some View {
        Button(action: {
            NotificationCenter.default.post(name: NSNotification.Name("SelectObject"), 
                                          object: ["type": type, "color": color])
        }) {
            VStack {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                Text(type.name)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(color.opacity(0.8))
            .cornerRadius(15)
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    print("✅ ContentView appeared")
                }
            
            VStack {
                HStack {
                    Text("AR Playground")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                    
                    Spacer()
                }
                .padding(.top, 100)
                
                Spacer()
                
                // Control Panel
                VStack(spacing: 16) {
                    Text("Tap to place objects • Drag to move • Pinch to scale")
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    
                    HStack(spacing: 20) {
                        ObjectButton(type: .cube, color: .red)
                        ObjectButton(type: .sphere, color: .blue) 
                        ObjectButton(type: .pyramid, color: .green)
                        ObjectButton(type: .cylinder, color: .purple)
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        NotificationCenter.default.post(name: NSNotification.Name("ResetAR"), object: nil)
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(25)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            print("🎯 ContentView body rendered")
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Extensions

extension SCNVector3 {
    func distance(to vector: SCNVector3) -> Float {
        let dx = x - vector.x
        let dy = y - vector.y
        let dz = z - vector.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    func midpoint(to vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            (x + vector.x) / 2,
            (y + vector.y) / 2,
            (z + vector.z) / 2
        )
    }
}