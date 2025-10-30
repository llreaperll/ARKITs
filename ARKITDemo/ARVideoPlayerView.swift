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
    @State private var isPlaying = false
    @State private var showingControls = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    
    var body: some View {
        ZStack {
            if cameraPermissionDenied {
                PermissionDeniedView(isPresented: $isPresented)
            } else {
                // AR Video Player
                ARVideoContainer(
                    isPlaying: $isPlaying,
                    currentTime: $currentTime,
                    duration: $duration
                )
                
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
                    
                    // Instructions and Controls
                    VStack(spacing: 12) {
                        if videoURL.isEmpty {
                            Text("📱 Tap \"Add Video\" to enter a video URL")
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.7))
                                .cornerRadius(10)
                        } else {
                            // Simple video controls at bottom
                            HStack(spacing: 20) {
                                // Backward 10s
                                Button(action: {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("SeekVideo"),
                                        object: ["action": "backward"]
                                    )
                                }) {
                                    Image(systemName: "gobackward.10")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                
                                // Play/Pause
                                Button(action: {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("TogglePlayPause"),
                                        object: nil
                                    )
                                }) {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                
                                // Forward 10s
                                Button(action: {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("SeekVideo"),
                                        object: ["action": "forward"]
                                    )
                                }) {
                                    Image(systemName: "goforward.10")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.black.opacity(0.8))
                            .cornerRadius(20)
                        }
                        
                        Text("🎯 Tap to place/move • 🖐️ Drag to reposition • 🤏 Pinch to resize")
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

// MARK: - Video Controls Overlay
struct VideoControlsOverlay: View {
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var showingControls: Bool
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Main control buttons
            HStack(spacing: 30) {
                // Backward 10s
                Button(action: {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SeekVideo"),
                        object: ["action": "backward"]
                    )
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Play/Pause
                Button(action: {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("TogglePlayPause"),
                        object: nil
                    )
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                // Forward 10s
                Button(action: {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SeekVideo"),
                        object: ["action": "forward"]
                    )
                }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.black.opacity(0.8))
            .cornerRadius(25)
            
            // Progress bar
            if duration > 0 {
                VStack(spacing: 8) {
                    // Seek bar
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(.white.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            // Progress
                            Rectangle()
                                .fill(.red)
                                .frame(width: max(0, CGFloat(currentTime / duration) * 200), height: 4)
                                .cornerRadius(2)
                        }
                        .frame(width: 200)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    let progress = min(max(0, value.location.x / 200), 1)
                                    let seekTime = progress * duration
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("SeekVideo"),
                                        object: ["action": "seek", "time": seekTime]
                                    )
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                        
                        Text(formatTime(duration))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.black.opacity(0.7))
                .cornerRadius(15)
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Video URL Input View (unchanged)
struct VideoURLInputView: View {
    @Binding var videoURL: String
    @Binding var isPresented: Bool
    @State private var tempURL: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                            
                            SampleURLButton(
                                title: "Tears of Steel",
                                url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
                                tempURL: $tempURL
                            )
                            
                            SampleURLButton(
                                title: "For Bigger Escapes",
                                url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
                                tempURL: $tempURL
                            )
                            
                            SampleURLButton(
                                title: "Sample Video HD",
                                url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4",
                                tempURL: $tempURL
                            )
                        }
                    }
                    
                    // Buttons at bottom
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
                    .padding(.top, 20)
                }
                .padding(20)
            }
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
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    @Binding var duration: Double
    
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
        coordinator.isPlaying = isPlaying
        coordinator.currentTime = currentTime
        coordinator.duration = duration
        
        // Setup notifications
        NotificationCenter.default.addObserver(coordinator,
                                             selector: #selector(VideoCoordinator.loadVideo(_:)),
                                             name: NSNotification.Name("LoadVideo"),
                                             object: nil)
        
        NotificationCenter.default.addObserver(coordinator,
                                             selector: #selector(VideoCoordinator.togglePlayPause),
                                             name: NSNotification.Name("TogglePlayPause"),
                                             object: nil)
        
        NotificationCenter.default.addObserver(coordinator,
                                             selector: #selector(VideoCoordinator.seekVideo(_:)),
                                             name: NSNotification.Name("SeekVideo"),
                                             object: nil)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.isPlaying = isPlaying
        context.coordinator.currentTime = currentTime
        context.coordinator.duration = duration
    }
    
    func makeCoordinator() -> VideoCoordinator {
        VideoCoordinator(
            isPlayingBinding: $isPlaying,
            currentTimeBinding: $currentTime,
            durationBinding: $duration
        )
    }
    
    // MARK: - Enhanced Video Coordinator
    class VideoCoordinator: NSObject, ARSCNViewDelegate {
        var arView: ARSCNView?
        var videoPlayer: AVPlayer?
        var videoPlayerItem: AVPlayerItem?
        var videoNode: SCNNode?
        var selectedNode: SCNNode?
        var videoScreen: SCNPlane?
        var timeObserver: Any?
        
        // Bindings
        var isPlayingBinding: Binding<Bool>
        var currentTimeBinding: Binding<Double>
        var durationBinding: Binding<Double>
        
        // Properties
        var isPlaying: Bool = false {
            didSet { isPlayingBinding.wrappedValue = isPlaying }
        }
        var currentTime: Double = 0 {
            didSet { currentTimeBinding.wrappedValue = currentTime }
        }
        var duration: Double = 0 {
            didSet { durationBinding.wrappedValue = duration }
        }
        
        let lightsNode: SCNNode = {
            let lightNode = SCNNode()
            let light = SCNLight()
            light.type = .omni
            light.intensity = 1000
            lightNode.light = light
            lightNode.position = SCNVector3(0, 10, 0)
            return lightNode
        }()
        
        init(isPlayingBinding: Binding<Bool>, currentTimeBinding: Binding<Double>, durationBinding: Binding<Double>) {
            self.isPlayingBinding = isPlayingBinding
            self.currentTimeBinding = currentTimeBinding
            self.durationBinding = durationBinding
        }
        
        @objc func loadVideo(_ notification: Notification) {
            guard let urlString = notification.object as? String,
                  let url = URL(string: urlString) else { return }
            
            print("🎬 Loading video: \(urlString)")
            
            // Remove existing video
            videoNode?.removeFromParentNode()
            videoPlayer?.pause()
            
            // Remove time observer
            if let observer = timeObserver {
                videoPlayer?.removeTimeObserver(observer)
                timeObserver = nil
            }
            
            // Create new video player
            videoPlayerItem = AVPlayerItem(url: url)
            videoPlayer = AVPlayer(playerItem: videoPlayerItem)
            
            // Add time observer
            let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserver = videoPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                self.currentTime = time.seconds
                
                if let duration = self.videoPlayerItem?.duration.seconds, duration.isFinite {
                    self.duration = duration
                }
                
                self.isPlaying = self.videoPlayer?.timeControlStatus == .playing
            }
            
            // Create video material
            let videoMaterial = SCNMaterial()
            videoMaterial.diffuse.contents = videoPlayer
            videoMaterial.emission.contents = videoPlayer
            videoMaterial.isDoubleSided = true
            
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
                
                // Make the video face the camera
                videoNode?.look(at: SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z))
            }
            
            // Add physics body for better interaction
            let shape = SCNPhysicsShape(geometry: videoScreen!, options: nil)
            videoNode?.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
            
            // Add to scene
            arView?.scene.rootNode.addChildNode(videoNode!)
            
            // Start playing
            videoPlayer?.play()
            
            print("✅ Video loaded and playing")
        }
        
        @objc func togglePlayPause() {
            guard let videoPlayer = videoPlayer else { return }
            
            if videoPlayer.timeControlStatus == .playing {
                videoPlayer.pause()
                print("⏸️ Video paused")
            } else {
                videoPlayer.play()
                print("▶️ Video playing")
            }
        }
        
        @objc func seekVideo(_ notification: Notification) {
            guard let videoPlayer = videoPlayer,
                  let data = notification.object as? [String: Any],
                  let action = data["action"] as? String else { return }
            
            switch action {
            case "forward":
                let newTime = videoPlayer.currentTime() + CMTime(seconds: 10, preferredTimescale: 1)
                videoPlayer.seek(to: newTime)
                print("⏭️ Seek forward 10s")
                
            case "backward":
                let newTime = videoPlayer.currentTime() - CMTime(seconds: 10, preferredTimescale: 1)
                videoPlayer.seek(to: max(newTime, CMTime.zero))
                print("⏮️ Seek backward 10s")
                
            case "seek":
                if let time = data["time"] as? Double {
                    let newTime = CMTime(seconds: time, preferredTimescale: 1)
                    videoPlayer.seek(to: newTime)
                    print("🎯 Seek to \(time)s")
                }
                
            default:
                break
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            
            let hitResults = arView.hitTest(location, options: [:])
            
            if let hitResult = hitResults.first {
                if hitResult.node.name == "videoPlayer" {
                    // Double tap on video - toggle play/pause
                    selectedNode = hitResult.node
                    highlightVideoNode(selectedNode!)
                    togglePlayPause()
                    
                    // Remove highlight after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.removeHighlight(hitResult.node)
                    }
                } else if hitResult.node.name?.contains("plane") != true {
                    // Tapped on other object - ignore
                    return
                }
            } else {
                // Tapped on empty space - move video there if it exists
                if videoNode != nil {
                    moveVideoToLocation(location)
                }
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let videoNode = videoNode,
                  let arView = arView else { return }
            
            let location = gesture.location(in: arView)
            
            switch gesture.state {
            case .began:
                selectedNode = videoNode
                highlightVideoNode(videoNode)
                
            case .changed:
                // Use multiple methods for smoother dragging
                var worldPosition: SCNVector3?
                
                // Method 1: Plane hit test
                let planeHitResults = arView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
                if let hitResult = planeHitResults.first {
                    worldPosition = SCNVector3(
                        hitResult.worldTransform.columns.3.x,
                        hitResult.worldTransform.columns.3.y + 0.2,
                        hitResult.worldTransform.columns.3.z
                    )
                }
                
                // Method 2: Feature points
                if worldPosition == nil {
                    let featureHitResults = arView.hitTest(location, types: [.featurePoint])
                    if let hitResult = featureHitResults.first {
                        worldPosition = SCNVector3(
                            hitResult.worldTransform.columns.3.x,
                            hitResult.worldTransform.columns.3.y + 0.2,
                            hitResult.worldTransform.columns.3.z
                        )
                    }
                }
                
                // Method 3: Keep same distance from camera
                if worldPosition == nil {
                    if let currentFrame = arView.session.currentFrame {
                        let screenPoint = CGPoint(x: location.x, y: location.y)
                        let cameraTransform = currentFrame.camera.transform
                        let cameraPosition = SCNVector3(
                            cameraTransform.columns.3.x,
                            cameraTransform.columns.3.y,
                            cameraTransform.columns.3.z
                        )
                        
                        // Project screen point to world at same distance as current video
                        let currentDistance = distance(videoNode.position, cameraPosition)
                        let ray = arView.unprojectPoint(SCNVector3(Float(screenPoint.x), Float(screenPoint.y), 0.5))
                        let direction = normalize(subtractVector(ray, cameraPosition))
                        worldPosition = addVector(cameraPosition, multiplyVector(direction, currentDistance))
                    }
                }
                
                if let position = worldPosition {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.05 // Faster updates for smoother dragging
                    videoNode.position = position
                    SCNTransaction.commit()
                }
                
            case .ended:
                removeHighlight(videoNode)
                selectedNode = nil
                
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let videoNode = videoNode else { return }
            
            switch gesture.state {
            case .began:
                selectedNode = videoNode
                highlightVideoNode(videoNode)
                
            case .changed:
                let scale = Float(gesture.scale)
                let currentScale = videoNode.scale
                let newScale = SCNVector3(
                    currentScale.x * scale,
                    currentScale.y * scale,
                    currentScale.z * scale
                )
                
                // Limit scale between 0.3x and 4x for better range
                let clampedScale = SCNVector3(
                    max(0.3, min(4.0, newScale.x)),
                    max(0.3, min(4.0, newScale.y)),
                    max(0.3, min(4.0, newScale.z))
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
                    hitResult.worldTransform.columns.3.y + 0.2,
                    hitResult.worldTransform.columns.3.z
                )
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                videoNode.position = position
                SCNTransaction.commit()
                
                print("📍 Moved video to new location")
            }
        }
        
        func highlightVideoNode(_ node: SCNNode) {
            let highlightAction = SCNAction.sequence([
                SCNAction.scale(to: 1.02, duration: 0.05),
                SCNAction.scale(to: 1.0, duration: 0.05)
            ])
            node.runAction(highlightAction)
        }
        
        func removeHighlight(_ node: SCNNode) {
            // Reset any highlighting
        }
        
        // Helper functions
        func distance(_ a: SCNVector3, _ b: SCNVector3) -> Float {
            let dx = a.x - b.x
            let dy = a.y - b.y
            let dz = a.z - b.z
            return sqrt(dx*dx + dy*dy + dz*dz)
        }
        
        func normalize(_ vector: SCNVector3) -> SCNVector3 {
            let length = sqrt(vector.x*vector.x + vector.y*vector.y + vector.z*vector.z)
            return SCNVector3(vector.x/length, vector.y/length, vector.z/length)
        }
        
        func subtractVector(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
            return SCNVector3(a.x - b.x, a.y - b.y, a.z - b.z)
        }
        
        func addVector(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
            return SCNVector3(a.x + b.x, a.y + b.y, a.z + b.z)
        }
        
        func multiplyVector(_ vector: SCNVector3, _ scalar: Float) -> SCNVector3 {
            return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
        }
        
        // MARK: - ARSCNViewDelegate
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x),
                                       height: CGFloat(planeAnchor.extent.z))
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.blue.withAlphaComponent(0.1)
            planeGeometry.materials = [material]
            
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            planeNode.name = "plane"
            
            node.addChildNode(planeNode)
        }
    }
}

#Preview {
    ARVideoPlayerView(isPresented: .constant(true))
}