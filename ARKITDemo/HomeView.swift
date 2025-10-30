import SwiftUI
import AVFoundation
import ARKit

struct HomeView: View {
    @State private var selectedCategory: ARCategory = .creative
    @State private var showingARView = false
    @State private var selectedExperience: ARExperience? = nil
    @State private var experienceToShow: ARExperience? = nil // Add this new state
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        HeroSection()
                        
                        // Category Selector
                        CategorySelector(selectedCategory: $selectedCategory)
                            .padding(.top, 40)
                        
                        // AR Experiences Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 20) {
                            ForEach(ARExperience.allExperiences.filter { $0.category == selectedCategory }) { experience in
                                ARExperienceCard(
                                    experience: experience,
                                    action: {
                                        print("🚀 Card action triggered for: \(experience.title)")
                                        print("🔍 Setting selectedExperience to: \(experience.id)")
                                        selectedExperience = experience
                                        experienceToShow = experience // Set both states
                                        print("🔍 selectedExperience is now: \(selectedExperience?.title ?? "nil")")
                                        print("🔍 experienceToShow is now: \(experienceToShow?.title ?? "nil")")
                                        showingARView = true
                                        print("🔧 showingARView set to: \(showingARView)")
                                        
                                        // Add a small delay to see if timing is the issue
                                        DispatchQueue.main.async {
                                            print("🕐 Async check - selectedExperience: \(selectedExperience?.title ?? "nil")")
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        
                        // Footer
                        FooterSection()
                            .padding(.top, 60)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingARView) {
            // Use experienceToShow instead of selectedExperience
            if let experience = experienceToShow {
                // Show actual AR experiences for ready ones
                switch experience.title {
                case "Object Playground":
                    ObjectPlaygroundView(isPresented: $showingARView)
                        .onAppear {
                            print("✅ Experience found: \(experience.title)")
                            print("🎮 Showing Object Playground")
                        }
                case "AR Video Player":
                    ARVideoPlayerView(isPresented: $showingARView)
                        .onAppear {
                            print("✅ Experience found: \(experience.title)")
                            print("🎬 Showing AR Video Player")
                        }
                case "YouTube Player":
                    YouTubeARPlayerView(isPresented: $showingARView)
                        .onAppear {
                            print("✅ Experience found: \(experience.title)")
                            print("📺 Showing YouTube Player")
                        }
                case "AR Ruler":
                    ARRulerView(isPresented: $showingARView)
                        .onAppear {
                            print("✅ Experience found: \(experience.title)")
                            print("📏 Showing AR Ruler")
                        }
                default:
                    ARExperienceView(experience: experience, isPresented: $showingARView)
                        .onAppear {
                            print("✅ Experience found: \(experience.title)")
                            print("🔄 Showing default experience: \(experience.title)")
                        }
                }
            } else {
                VStack {
                    Text("No experience selected")
                        .foregroundColor(.white)
                        .font(.title)
                        .padding()
                    
                    Text("Debug: experienceToShow is nil")
                        .foregroundColor(.red)
                        .padding()
                    
                    Button("Back") {
                        showingARView = false
                        experienceToShow = nil // Clear both when closing
                        selectedExperience = nil
                    }
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .onAppear {
                    print("❌ No experience selected - experienceToShow is nil")
                    print("🔍 showingARView: \(showingARView)")
                }
            }
        }
        .onChange(of: showingARView) { oldValue, newValue in
            if !newValue {
                // Clear the experience when sheet is dismissed
                experienceToShow = nil
                selectedExperience = nil
                print("🧹 Cleared experience states")
            }
        }
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Floating AR Icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 10)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue, .purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: "arkit")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            // Title and subtitle
            VStack(spacing: 12) {
                Text("ARKit Studio")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("Explore the future with immersive\naugmented reality experiences")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Category Selector
struct CategorySelector: View {
    @Binding var selectedCategory: ARCategory
    @Namespace private var animation
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ARCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        animation: animation,
                        action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct CategoryButton: View {
    let category: ARCategory
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(category.title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.white)
                        .matchedGeometryEffect(id: "categoryBackground", in: animation)
                } else {
                    Capsule()
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - AR Experience Card
struct ARExperienceCard: View {
    let experience: ARExperience
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            print("🎯 Tapped experience: \(experience.title)")
            action()
        }) {
            VStack(spacing: 0) {
                // Icon and gradient background
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: experience.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    // Icon
                    Image(systemName: experience.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(experience.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(experience.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    // Features
                    HStack(spacing: 8) {
                        ForEach(experience.features.prefix(2), id: \.self) { feature in
                            Text(feature)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .lineLimit(2)
                                .background(.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        if experience.features.count > 2 {
                            Text("+\(experience.features.count - 2)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    
                    // Status badge
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(experience.status.color)
                                .frame(width: 6, height: 6)
                            
                            Text(experience.status.title)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.3))
                        .cornerRadius(12)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial.opacity(0.8))
            }
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: isHovered ? 20 : 10, x: 0, y: isHovered ? 10 : 5)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Footer Section
struct FooterSection: View {
    var body: some View {
        VStack(spacing: 24) {
            // Stats
            HStack(spacing: 40) {
                StatItem(number: "12", label: "Experiences")
                StatItem(number: "4", label: "Categories")
                StatItem(number: "iOS 15+", label: "Compatible")
            }
            
            // Made with love
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("Made with")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                    
                    Text("and ARKit")
                        .foregroundColor(.white.opacity(0.6))
                }
                .font(.system(size: 14, weight: .medium))
                
                Text("Tap any experience to begin your AR journey")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.bottom, 40)
    }
}

struct StatItem: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Animated Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.3, green: 0.1, blue: 0.4),
                        Color(red: 0.1, green: 0.2, blue: 0.5),
                        Color(red: 0.2, green: 0.1, blue: 0.3)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
    }
}

// MARK: - Enhanced Placeholder AR Experience View
struct ARExperienceView: View {
    let experience: ARExperience
    @Binding var isPresented: Bool
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Gradient background matching the card
            LinearGradient(
                colors: experience.gradientColors + [Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .blur(radius: 30)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Image(systemName: experience.icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: isAnimating)
                }
                
                VStack(spacing: 16) {
                    Text(experience.title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(experience.description)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                    
                    // Features list
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(experience.features, id: \.self) { feature in
                            Text(feature)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                }
                
                VStack(spacing: 20) {
                    // Status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(experience.status.color)
                            .frame(width: 8, height: 8)
                        
                        Text(experience.status == .comingSoon ? "Coming Soon" : experience.status == .beta ? "In Development" : "Available")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(experience.status.color)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.3))
                    .cornerRadius(16)
                    
                    // Back button
                    Button("Back to Home") {
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.white.opacity(0.2))
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(20)
            .onAppear {
                isAnimating = true
            }
            
            // Back button in top corner
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

// MARK: - Object Playground Wrapper
struct ObjectPlaygroundView: View {
    @Binding var isPresented: Bool
    @State private var showingPermissionAlert = false
    @State private var cameraPermissionDenied = false
    
    var body: some View {
        ZStack {
            if cameraPermissionDenied {
                // Show permission denied screen
                PermissionDeniedView(isPresented: $isPresented)
            } else {
                // Show AR experience
                ContentView()
                
                // Back button overlay - positioned to not overlap with AR Playground title
                VStack {
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
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 60) // Increased from 50 to 60 to avoid overlap
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkCameraPermission()
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Camera access already granted
            cameraPermissionDenied = false
            
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionDenied = !granted
                }
            }
            
        case .denied, .restricted:
            // Permission denied
            cameraPermissionDenied = true
            
        @unknown default:
            cameraPermissionDenied = true
        }
    }
}

// MARK: - Simple Debug Object Playground
//struct ObjectPlaygroundView: View {
//    @Binding var isPresented: Bool
//    
//    var body: some View {
//        ZStack {
//            // Bright red background so we can see if this view loads
//            Color.red.ignoresSafeArea()
//            
//            VStack(spacing: 20) {
//                Text("OBJECT PLAYGROUND DEBUG")
//                    .font(.title)
//                    .foregroundColor(.white)
//                    .onAppear {
//                        print("🔴 ObjectPlaygroundView appeared!")
//                    }
//                
//                Text("If you see this, navigation is working")
//                    .foregroundColor(.white)
//                
//                Button("Test ContentView") {
//                    print("🔵 Test button tapped")
//                }
//                .padding()
//                .background(.blue)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//                
//                Button("Back") {
//                    print("🔙 Back button tapped")
//                    isPresented = false
//                }
//                .padding()
//                .background(.green)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//            }
//        }
//        .navigationBarHidden(true)
//        .onAppear {
//            print("🎯 ObjectPlaygroundView body rendered")
//        }
//    }
//}

// MARK: - Permission Denied View
struct PermissionDeniedView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                VStack(spacing: 16) {
                    Text("Camera Permission Required")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("This AR experience needs camera access to work. Please enable camera permission in Settings.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 16) {
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .cornerRadius(20)
                    
                    Button("Back to Home") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.2))
                    .cornerRadius(20)
                }
            }
            .padding(20)
            
            // Back button in top corner
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

// MARK: - AR Ruler Placeholder (for the other ready experience)
struct ARRulerView: View {
    @Binding var isPresented: Bool
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.gray, Color.blue, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated ruler icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .blur(radius: 30)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: isAnimating)
                }
                
                VStack(spacing: 16) {
                    Text("AR Ruler")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Measure objects in the real world\nwith precision AR technology")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    // Features
                    HStack(spacing: 12) {
                        Text("Measuring")
                        Text("Precision")
                        Text("Units")
                        Text("Save")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                }
                
                VStack(spacing: 20) {
                    Text("Coming Soon")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.3))
                        .cornerRadius(16)
                    
                    Button("Back to Home") {
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.white.opacity(0.2))
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(20)
            .onAppear {
                isAnimating = true
            }
            
            // Back button in top corner
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

// MARK: - Data Models
enum ARCategory: String, CaseIterable {
    case creative = "Creative"
    case games = "Games"
    case education = "Education"
    case tools = "Tools"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .creative: return "paintbrush.fill"
        case .games: return "gamecontroller.fill"
        case .education: return "graduationcap.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        }
    }
}

enum ARStatus {
    case ready
    case comingSoon
    case beta
    
    var title: String {
        switch self {
        case .ready: return "Ready"
        case .comingSoon: return "Soon"
        case .beta: return "Beta"
        }
    }
    
    var color: Color {
        switch self {
        case .ready: return .green
        case .comingSoon: return .orange
        case .beta: return .blue
        }
    }
}

struct ARExperience: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: ARCategory
    let gradientColors: [Color]
    let features: [String]
    let status: ARStatus
    
    static let allExperiences: [ARExperience] = [
        // Creative Experiences
        ARExperience(
            title: "Object Playground",
            description: "Place and manipulate 3D objects in your space",
            icon: "cube.transparent",
            category: .creative,
            gradientColors: [.blue, .purple],
            features: ["Multi-touch", "Physics", "7 Objects", "Materials"],
            status: .ready
        ),
        ARExperience(
            title: "AR Video Player",
            description: "Watch videos floating in your real space",
            icon: "play.rectangle.fill",
            category: .creative,
            gradientColors: [.red, .pink],
            features: ["URL Support", "Controls", "Resize", "Position"],
            status: .ready
        ),
        ARExperience(
            title: "YouTube Player",
            description: "Watch YouTube videos in fullscreen AR",
            icon: "play.tv.fill",
            category: .creative,
            gradientColors: [.red, .orange],
            features: ["YouTube", "Fullscreen", "WebView", "Controls"],
            status: .ready
        ),
        ARExperience(
            title: "AR Paint Studio",
            description: "Paint and draw in 3D space with virtual brushes",
            icon: "paintbrush.pointed.fill",
            category: .creative,
            gradientColors: [.pink, .orange],
            features: ["3D Painting", "Brushes", "Colors", "Save"],
            status: .comingSoon
        ),
        ARExperience(
            title: "Sculpture Garden",
            description: "Create beautiful sculptures with virtual clay",
            icon: "hands.and.sparkles.fill",
            category: .creative,
            gradientColors: [.green, .teal],
            features: ["Sculpting", "Materials", "Gallery", "Export"],
            status: .beta
        ),
        ARExperience(
            title: "Light Designer",
            description: "Design lighting effects and ambiences",
            icon: "lightbulb.max.fill",
            category: .creative,
            gradientColors: [.yellow, .orange],
            features: ["HDR Lights", "Colors", "Shadows", "Presets"],
            status: .comingSoon
        ),
        
        // Games Experiences
        ARExperience(
            title: "AR Tower Defense",
            description: "Defend your space from virtual invaders",
            icon: "shield.lefthalf.filled",
            category: .games,
            gradientColors: [.red, .pink],
            features: ["Strategy", "Enemies", "Towers", "Levels"],
            status: .comingSoon
        ),
        ARExperience(
            title: "Portal Adventures",
            description: "Step through magical portals to new worlds",
            icon: "circle.hexagongrid.fill",
            category: .games,
            gradientColors: [.purple, .blue],
            features: ["Portals", "Worlds", "Adventure", "Magic"],
            status: .beta
        ),
        ARExperience(
            title: "Virtual Pet Care",
            description: "Take care of your virtual pet in AR",
            icon: "pawprint.fill",
            category: .games,
            gradientColors: [.green, .mint],
            features: ["Pet AI", "Care", "Games", "Growth"],
            status: .comingSoon
        ),
        ARExperience(
            title: "AR Puzzle Solver",
            description: "Solve 3D puzzles floating in space",
            icon: "puzzlepiece.extension.fill",
            category: .games,
            gradientColors: [.indigo, .purple],
            features: ["3D Puzzles", "Hints", "Levels", "Timer"],
            status: .comingSoon
        ),
        
        // Education Experiences
        ARExperience(
            title: "Solar System",
            description: "Explore planets and stars in your room",
            icon: "globe.americas.fill",
            category: .education,
            gradientColors: [.blue, .indigo],
            features: ["Planets", "Orbits", "Facts", "Scale"],
            status: .beta
        ),
        ARExperience(
            title: "Anatomy Explorer",
            description: "Learn human anatomy with 3D models",
            icon: "figure.walk",
            category: .education,
            gradientColors: [.red, .orange],
            features: ["3D Body", "Systems", "Labels", "Quiz"],
            status: .comingSoon
        ),
        ARExperience(
            title: "Chemistry Lab",
            description: "Conduct virtual chemistry experiments",
            icon: "testtube.2",
            category: .education,
            gradientColors: [.green, .yellow],
            features: ["Molecules", "Reactions", "Safe", "Learn"],
            status: .comingSoon
        ),
        ARExperience(
            title: "History Timeline",
            description: "Walk through historical events in 3D",
            icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
            category: .education,
            gradientColors: [.brown, .orange],
            features: ["Timeline", "Events", "3D", "Interactive"],
            status: .comingSoon
        ),
        
        // Tools Experiences
        ARExperience(
            title: "AR Ruler",
            description: "Measure real world objects precisely",
            icon: "ruler.fill",
            category: .tools,
            gradientColors: [.gray, .blue],
            features: ["Measuring", "Precision", "Units", "Save"],
            status: .ready
        ),
        ARExperience(
            title: "Room Planner",
            description: "Plan and design your room layout",
            icon: "house.fill",
            category: .tools,
            gradientColors: [.teal, .green],
            features: ["Planning", "Furniture", "3D", "Share"],
            status: .beta
        ),
        ARExperience(
            title: "QR Code Scanner",
            description: "Scan and create QR codes in AR",
            icon: "qrcode.viewfinder",
            category: .tools,
            gradientColors: [.black, .gray],
            features: ["Scan", "Create", "Share", "History"],
            status: .ready
        ),
        ARExperience(
            title: "AR Whiteboard",
            description: "Collaborative whiteboard in 3D space",
            icon: "rectangle.and.pencil.and.ellipsis",
            category: .tools,
            gradientColors: [.white, .gray],
            features: ["Drawing", "Notes", "Share", "Sync"],
            status: .comingSoon
        )
    ]
}

#Preview {
    HomeView()
}