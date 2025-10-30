import SwiftUI
import ARKit
import SceneKit
import AVFoundation
import AVKit

struct ARVideoPlayerView: View {
    @Binding var isPresented: Bool
    @State private var videoURL: String = ""
    @State private var showingURLInput = false
    @State private var cameraPermissionDenied = false
    
    var body: some View {
        ZStack {
            if cameraPermissionDenied {
                PermissionDeniedView(isPresented: $isPresented)
            } else {
                // AR Video Player
                ARVideoContainer()
                
                // Top overlay with controls
                VStack {
                    // Top bar
                    HStack {
                        Button(action: {
                            isPresented = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.7))
                            .cornerRadius(15)
                        }
                        
                        Spacer()
                        
                        Text("AR Video Player")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.7))
                            .cornerRadius(20)
                        
                        Spacer()
                        
                        Button(action: {
                            showingURLInput = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.7))
                                .cornerRadius(15)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 12) {
                        Text("📱 Tap \"Add Video\" to enter a video URL")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.7))
                            .cornerRadius(10)
                        
                        Text("🎯 Tap to place video • 🖐️ Drag to move • 🤏 Pinch to resize")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkCameraPermission()
        }
        .sheet(isPresented: $showingURLInput) {
            VideoURLInputView(videoURL: $videoURL, isPresented: $showingURLInput)
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionDenied = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionDenied = !granted
                }
            }
        case .denied, .restricted:
            cameraPermissionDenied = true
        @unknown default:
            cameraPermissionDenied = true
        }
    }
}

// MARK: - Video URL Input View
struct VideoURLInputView: View {
    @Binding var videoURL: String
    @Binding var isPresented: Bool
    @State private var tempURL: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Add Video URL")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter a video URL to play in AR space")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Video URL")
                        .font(.headline)
                    
                    TextField("https://example.com/video.mp4", text: $tempURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                
                // Sample URLs
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample Videos")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        SampleURLButton(
                            title: "Big Buck Bunny",
                            url: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                            tempURL: $tempURL
                        )
                        
                        SampleURLButton(
                            title: "Elephant Dream",
                            url: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
                            tempURL: $tempURL
                        )
                        
                        SampleURLButton(
                            title: "Sintel",
                            url: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
                            tempURL: $tempURL
                        )
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.red.opacity(0.1))
                    .cornerRadius(12)
                    
                    Button("Add Video") {
                        videoURL = tempURL
                        NotificationCenter.default.post(
                            name: NSNotification.Name("LoadVideo"),
                            object: tempURL
                        )
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(tempURL.isEmpty ? .gray : .blue)
                    .cornerRadius(12)
                    .disabled(tempURL.isEmpty)
                }
            }
            .padding(20)
            .navigationTitle("Video Player")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            tempURL = videoURL
        }
    }
}

struct SampleURLButton: View {
    let title: String
    let url: String
    @Binding var tempURL: String
    
    var body: some View {
        Button(action: {
            tempURL = url
        }) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.blue)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.up.right.circle")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - AR Video Container
struct ARVideoContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        let coordinator = context.coordinator
        
        // Setup AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)
        
        // Setup scene
        arView.delegate = coordinator
        arView.scene.rootNode.addChildNode(coordinator.lightsNode)
        
        // Add gesture recognizers for video control
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(VideoCoordinator.handleTap(_:)))
        let panGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(VideoCoordinator.handlePan(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(VideoCoordinator.handlePinch(_:)))
        
        arView.addGestureRecognizer(tapGesture)
        arView.addGestureRecognizer(panGesture)
        arView.addGestureRecognizer(pinchGesture)
        
        coordinator.arView = arView
        
        // Setup notifications
        NotificationCenter.default.addObserver(coordinator,
                                             selector: #selector(VideoCoordinator.loadVideo(_:)),
                                             name: NSNotification.Name("LoadVideo"),
                                             object: nil)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Updates can be handled here if needed
    }
    
    func makeCoordinator() -> VideoCoordinator {
        VideoCoordinator()
    }
    
    // MARK: - Video Coordinator
    class VideoCoordinator: NSObject, ARSCNViewDelegate {
        var arView: ARSCNView?
        var videoPlayer: AVPlayer?
        var videoNode: SCNNode?
        var selectedNode: SCNNode?
        var videoScreen: SCNPlane?
        
        let lightsNode: SCNNode = {
            let lightNode = SCNNode()
            let light = SCNLight()
            light.type = .omni
            light.intensity = 1000
            lightNode.light = light
            lightNode.position = SCNVector3(0, 10, 0)
            return lightNode
        }()
        
        @objc func loadVideo(_ notification: Notification) {
            guard let urlString = notification.object as? String,
                  let url = URL(string: urlString) else { return }
            
            print("🎬 Loading video: \(urlString)")
            
            // Remove existing video
            videoNode?.removeFromParentNode()
            videoPlayer?.pause()
            
            // Create new video player
            videoPlayer = AVPlayer(url: url)
            
            // Create video material
            let videoMaterial = SCNMaterial()
            videoMaterial.diffuse.contents = videoPlayer
            videoMaterial.emission.contents = videoPlayer // Make it self-illuminating
            
            // Create video screen geometry
            videoScreen = SCNPlane(width: 1.6, height: 0.9) // 16:9 aspect ratio
            videoScreen?.materials = [videoMaterial]
            
            // Create video node
            videoNode = SCNNode(geometry: videoScreen)
            videoNode?.name = "videoPlayer"
            
            // Position the video screen in front of camera
            if let currentFrame = arView?.session.currentFrame {
                let transform = currentFrame.camera.transform
                let position = SCNVector3(
                    transform.columns.3.x,
                    transform.columns.3.y,
                    transform.columns.3.z - 2.0
                )
                videoNode?.position = position
            }
            
            // Add to scene
            arView?.scene.rootNode.addChildNode(videoNode!)
            
            // Start playing
            videoPlayer?.play()
            
            print("✅ Video loaded and playing")
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            
            let hitResults = arView.hitTest(location, options: [:])
            
            if let hitResult = hitResults.first {
                if hitResult.node.name == "videoPlayer" {
                    // Tapped on video - toggle play/pause
                    selectedNode = hitResult.node
                    highlightVideoNode(selectedNode!)
                    togglePlayPause()
                } else {
                    // Tapped elsewhere - move video to that location
                    moveVideoToLocation(location)
                }
            } else {
                // Tapped on empty space - move video there
                moveVideoToLocation(location)
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let selectedNode = selectedNode,
                  let arView = arView else { return }
            
            let location = gesture.location(in: arView)
            
            switch gesture.state {
            case .began:
                selectedNode.physicsBody?.type = .kinematic
                
            case .changed:
                let planeHitResults = arView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
                if let hitResult = planeHitResults.first {
                    let position = SCNVector3(
                        hitResult.worldTransform.columns.3.x,
                        hitResult.worldTransform.columns.3.y + 0.1,
                        hitResult.worldTransform.columns.3.z
                    )
                    
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.1
                    selectedNode.position = position
                    SCNTransaction.commit()
                }
                
            case .ended:
                selectedNode.physicsBody?.type = .static
                removeHighlight(selectedNode)
                self.selectedNode = nil
                
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let videoNode = videoNode else { return }
            
            switch gesture.state {
            case .began:
                selectedNode = videoNode
                highlightVideoNode(selectedNode!)
                
            case .changed:
                let scale = Float(gesture.scale)
                let currentScale = videoNode.scale
                let newScale = SCNVector3(
                    currentScale.x * scale,
                    currentScale.y * scale,
                    currentScale.z * scale
                )
                
                // Limit scale between 0.5x and 3x
                let clampedScale = SCNVector3(
                    max(0.5, min(3.0, newScale.x)),
                    max(0.5, min(3.0, newScale.y)),
                    max(0.5, min(3.0, newScale.z))
                )
                
                videoNode.scale = clampedScale
                gesture.scale = 1.0
                
            case .ended:
                removeHighlight(videoNode)
                selectedNode = nil
                
            default:
                break
            }
        }
        
        func moveVideoToLocation(_ screenLocation: CGPoint) {
            guard let arView = arView, let videoNode = videoNode else { return }
            
            let planeHitResults = arView.hitTest(screenLocation, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
            if let hitResult = planeHitResults.first {
                let position = SCNVector3(
                    hitResult.worldTransform.columns.3.x,
                    hitResult.worldTransform.columns.3.y + 0.1,
                    hitResult.worldTransform.columns.3.z
                )
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                videoNode.position = position
                SCNTransaction.commit()
                
                print("📍 Moved video to new location")
            }
        }
        
        func togglePlayPause() {
            guard let videoPlayer = videoPlayer else { return }
            
            if videoPlayer.timeControlStatus == .playing {
                videoPlayer.pause()
                print("⏸️ Video paused")
            } else {
                videoPlayer.play()
                print("▶️ Video playing")
            }
        }
        
        func highlightVideoNode(_ node: SCNNode) {
            let highlightAction = SCNAction.sequence([
                SCNAction.scale(to: 1.05, duration: 0.1),
                SCNAction.scale(to: 1.0, duration: 0.1)
            ])
            node.runAction(highlightAction)
            
            // Add glow effect
            node.geometry?.materials.forEach { material in
                material.emission.intensity = 1.2
            }
            
            print("🎬 Video highlighted")
        }
        
        func removeHighlight(_ node: SCNNode) {
            node.geometry?.materials.forEach { material in
                material.emission.intensity = 1.0
            }
        }
        
        // MARK: - ARSCNViewDelegate
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x),
                                       height: CGFloat(planeAnchor.extent.z))
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.blue.withAlphaComponent(0.2)
            planeGeometry.materials = [material]
            
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            
            node.addChildNode(planeNode)
        }
    }
}

#Preview {
    ARVideoPlayerView(isPresented: .constant(true))
}