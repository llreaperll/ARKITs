import SwiftUI
import WebKit
import ARKit
import SceneKit
import AVFoundation

struct YouTubeARPlayerView: View {
    @Binding var isPresented: Bool
    @State private var youtubeURL: String = ""
    @State private var showingURLInput = false
    @State private var cameraPermissionDenied = false
    @State private var videoPosition: CGPoint = .zero
    @State private var showingVideo = false
    
    var body: some View {
        ZStack {
            if cameraPermissionDenied {
                PermissionDeniedView(isPresented: $isPresented)
            } else {
                // AR Camera View with 3D Tracking
                YouTubeARContainer(
                    youtubeURL: youtubeURL,
                    videoPosition: $videoPosition,
                    showingVideo: $showingVideo
                )
                
                // YouTube Video Overlay (positioned based on AR tracking)
                if showingVideo && !youtubeURL.isEmpty {
                    YouTubeVideoOverlay(
                        url: youtubeURL,
                        position: videoPosition
                    )
                }
                
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
                        
                        Text("YouTube AR Player")
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
                    
                    // Instructions at bottom
                    VStack(spacing: 12) {
                        if youtubeURL.isEmpty {
                            Text("📱 Tap \"Add Video\" to enter a YouTube URL")
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.7))
                                .cornerRadius(10)
                        } else if showingVideo {
                            HStack(spacing: 15) {
                                Button(action: {
                                    showingVideo = false
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "eye.slash.fill")
                                        Text("Hide")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.red.opacity(0.8))
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    // Reset video to center
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ResetYouTubeVideo"),
                                        object: nil
                                    )
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Reset")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.8))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.7))
                            .cornerRadius(15)
                        } else {
                            Button(action: {
                                showingVideo = true
                            }) {
                                Text("📺 Show Video Player")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.green.opacity(0.8))
                                    .cornerRadius(10)
                            }
                        }
                        
                        Text("🎯 Tap to place video • Move around to see AR tracking")
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
            YouTubeURLInputView(youtubeURL: $youtubeURL, isPresented: $showingURLInput) {
                showingVideo = true
                NotificationCenter.default.post(
                    name: NSNotification.Name("LoadYouTubeVideo"),
                    object: youtubeURL
                )
            }
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

// MARK: - YouTube AR Container with Lightweight Tracking
struct YouTubeARContainer: UIViewRepresentable {
    let youtubeURL: String
    @Binding var videoPosition: CGPoint
    @Binding var showingVideo: Bool
    
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
        
        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(YouTubeARCoordinator.handleTap(_:)))
        
        arView.addGestureRecognizer(tapGesture)
        
        coordinator.arView = arView
        coordinator.videoPosition = videoPosition
        coordinator.showingVideo = showingVideo
        coordinator.onPositionUpdate = { position in
            DispatchQueue.main.async {
                self.videoPosition = position
            }
        }
        
        // Setup notifications
        NotificationCenter.default.addObserver(coordinator,
                                             selector: #selector(YouTubeARCoordinator.loadYouTubeVideo(_:)),
                                             name: NSNotification.Name("LoadYouTubeVideo"),
                                             object: nil)
        
        NotificationCenter.default.addObserver(coordinator,
                                             selector: #selector(YouTubeARCoordinator.resetVideo),
                                             name: NSNotification.Name("ResetYouTubeVideo"),
                                             object: nil)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.videoPosition = videoPosition
        context.coordinator.showingVideo = showingVideo
        
        if !youtubeURL.isEmpty && context.coordinator.placeholderNode == nil {
            context.coordinator.loadYouTubeVideo(url: youtubeURL)
        }
    }
    
    func makeCoordinator() -> YouTubeARCoordinator {
        YouTubeARCoordinator()
    }
    
    // MARK: - Lightweight YouTube AR Coordinator
    class YouTubeARCoordinator: NSObject, ARSCNViewDelegate {
        var arView: ARSCNView?
        var placeholderNode: SCNNode?
        var videoAnchor: ARAnchor?
        var videoPosition: CGPoint = .zero
        var showingVideo: Bool = false
        var onPositionUpdate: ((CGPoint) -> Void)?
        
        let lightsNode: SCNNode = {
            let lightNode = SCNNode()
            let light = SCNLight()
            light.type = .omni
            light.intensity = 1000
            lightNode.light = light
            lightNode.position = SCNVector3(0, 10, 0)
            return lightNode
        }()
        
        @objc func loadYouTubeVideo(_ notification: Notification) {
            guard let urlString = notification.object as? String else { return }
            loadYouTubeVideo(url: urlString)
        }
        
        func loadYouTubeVideo(url: String) {
            guard let arView = arView else { return }
            
            print("📺 Loading YouTube placeholder in AR: \(url)")
            
            // Remove existing placeholder
            placeholderNode?.removeFromParentNode()
            if let existingAnchor = videoAnchor {
                arView.session.remove(anchor: existingAnchor)
            }
            
            // Create a simple placeholder (invisible but trackable)
            let placeholderScreen = SCNPlane(width: 1.6, height: 0.9)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.clear
            material.isDoubleSided = false
            placeholderScreen.materials = [material]
            
            // Create placeholder node
            placeholderNode = SCNNode(geometry: placeholderScreen)
            placeholderNode?.name = "youtubePlaceholder"
            
            // Position in front of camera initially
            if let currentFrame = arView.session.currentFrame {
                let cameraTransform = currentFrame.camera.transform
                
                let anchorMatrix = matrix_multiply(cameraTransform, matrix_float4x4(
                    [1, 0, 0, 0],
                    [0, 1, 0, 0],
                    [0, 0, 1, -2], // 2 meters in front
                    [0, 0, 0, 1]
                ))
                
                videoAnchor = ARAnchor(transform: anchorMatrix)
                arView.session.add(anchor: videoAnchor!)
            }
            
            print("✅ YouTube placeholder loaded in AR")
        }
        
        @objc func resetVideo() {
            guard let arView = arView else { return }
            
            // Remove existing anchor
            if let existingAnchor = videoAnchor {
                arView.session.remove(anchor: existingAnchor)
            }
            
            // Place in front of camera again
            if let currentFrame = arView.session.currentFrame {
                let cameraTransform = currentFrame.camera.transform
                
                let anchorMatrix = matrix_multiply(cameraTransform, matrix_float4x4(
                    [1, 0, 0, 0],
                    [0, 1, 0, 0],
                    [0, 0, 1, -2],
                    [0, 0, 0, 1]
                ))
                
                videoAnchor = ARAnchor(transform: anchorMatrix)
                arView.session.add(anchor: videoAnchor!)
                
                print("🔄 Reset YouTube video position")
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            
            // Try to place video at tap location
            let hitResults = arView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane, .featurePoint])
            
            if let hitResult = hitResults.first {
                // Remove old anchor
                if let oldAnchor = videoAnchor {
                    arView.session.remove(anchor: oldAnchor)
                }
                
                // Create new anchor at tap location
                let newTransform = hitResult.worldTransform
                videoAnchor = ARAnchor(transform: newTransform)
                arView.session.add(anchor: videoAnchor!)
                
                print("📍 Moved YouTube video to tap location")
            }
        }
        
        // MARK: - ARSCNViewDelegate
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            // Update video position based on 3D tracking
            guard let arView = arView,
                  let placeholderNode = placeholderNode,
                  showingVideo else { return }
            
            // Project 3D position to screen coordinates
            let screenPosition = arView.projectPoint(placeholderNode.presentation.position)
            let newPosition = CGPoint(x: CGFloat(screenPosition.x), y: CGFloat(screenPosition.y))
            
            // Only update if position changed significantly
            let distance = sqrt(pow(newPosition.x - videoPosition.x, 2) + pow(newPosition.y - videoPosition.y, 2))
            if distance > 5 {
                DispatchQueue.main.async {
                    self.onPositionUpdate?(newPosition)
                }
            }
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // Handle plane anchors
            if let planeAnchor = anchor as? ARPlaneAnchor {
                let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x),
                                           height: CGFloat(planeAnchor.extent.z))
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.blue.withAlphaComponent(0.05)
                planeGeometry.materials = [material]
                
                let planeNode = SCNNode(geometry: planeGeometry)
                planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
                planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
                planeNode.name = "plane"
                
                node.addChildNode(planeNode)
            }
            // Handle video anchor
            else if anchor == videoAnchor, let placeholderNode = placeholderNode {
                node.addChildNode(placeholderNode)
                print("📍 YouTube placeholder anchored in AR space")
            }
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            // Update plane anchors
            if let planeAnchor = anchor as? ARPlaneAnchor,
               let planeNode = node.childNodes.first,
               let plane = planeNode.geometry as? SCNPlane {
                
                plane.width = CGFloat(planeAnchor.extent.x)
                plane.height = CGFloat(planeAnchor.extent.z)
                planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            }
        }
    }
}

// MARK: - YouTube Video Overlay (Performance Optimized)
struct YouTubeVideoOverlay: View {
    let url: String
    let position: CGPoint
    @State private var webViewSize: CGSize = CGSize(width: 320, height: 180)
    
    var body: some View {
        YouTubeWebView(urlString: url)
            .frame(width: webViewSize.width, height: webViewSize.height)
            .background(Color.black)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .position(x: position.x, y: position.y)
            .scaleEffect(0.8) // Slightly smaller for performance
            .overlay(
                // Resize handle (bottom-right corner)
                Circle()
                    .fill(.white.opacity(0.8))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(.blue, lineWidth: 1.5)
                    )
                    .position(
                        x: position.x + (webViewSize.width * 0.8) / 2 - 8,
                        y: position.y + (webViewSize.height * 0.8) / 2 - 8
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newWidth = max(240, min(400, webViewSize.width + value.translation.width))
                                let newHeight = newWidth * 0.5625 // Maintain 16:9 aspect ratio
                                webViewSize = CGSize(width: newWidth, height: newHeight)
                            }
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: position)
    }
}

// MARK: - YouTube WebView (Optimized)
struct YouTubeWebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsPictureInPictureMediaPlayback = false
        
        // Performance optimizations
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = UIColor.black
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.bounces = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - YouTube URL Input View
struct YouTubeURLInputView: View {
    @Binding var youtubeURL: String
    @Binding var isPresented: Bool
    @State private var tempURL: String = ""
    let onVideoLoaded: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "play.tv.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Add YouTube Video")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Enter a YouTube URL to place in AR space")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YouTube URL")
                            .font(.headline)
                        
                        TextField("https://www.youtube.com/watch?v=...", text: $tempURL)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                    
                    // Sample YouTube URLs
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular Videos")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            YouTubeSampleButton(
                                title: "🎵 Music Video",
                                description: "Popular music content",
                                url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                                tempURL: $tempURL
                            )
                            
                            YouTubeSampleButton(
                                title: "🎬 Movie Trailers",
                                description: "Latest movie previews",
                                url: "https://www.youtube.com/watch?v=TcMBFSGVi1c",
                                tempURL: $tempURL
                            )
                            
                            YouTubeSampleButton(
                                title: "📚 Educational Content",
                                description: "Learn something new",
                                url: "https://www.youtube.com/watch?v=wJyUtbn0O5Y",
                                tempURL: $tempURL
                            )
                            
                            YouTubeSampleButton(
                                title: "🎮 Gaming Videos",
                                description: "Gameplay and reviews",
                                url: "https://www.youtube.com/watch?v=BQ0mxQXmLsk",
                                tempURL: $tempURL
                            )
                            
                            YouTubeSampleButton(
                                title: "🔬 Science & Tech",
                                description: "Latest in technology",
                                url: "https://www.youtube.com/watch?v=thOifuHs6eY",
                                tempURL: $tempURL
                            )
                        }
                    }
                    
                    // Info section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ℹ️ How to use:")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• Copy any YouTube video URL\n• Paste it in the field above\n• Tap 'Load Video' to place in AR\n• Move around to see 3D tracking!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Buttons
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
                        
                        Button("Load Video") {
                            youtubeURL = tempURL
                            isPresented = false
                            onVideoLoaded()
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(tempURL.isEmpty ? .gray : .red)
                        .cornerRadius(12)
                        .disabled(tempURL.isEmpty)
                    }
                    .padding(.top, 20)
                }
                .padding(20)
            }
            .navigationTitle("YouTube Player")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            tempURL = youtubeURL
        }
    }
}

struct YouTubeSampleButton: View {
    let title: String
    let description: String
    let url: String
    @Binding var tempURL: String
    
    var body: some View {
        Button(action: {
            tempURL = url
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    YouTubeARPlayerView(isPresented: .constant(true))
}