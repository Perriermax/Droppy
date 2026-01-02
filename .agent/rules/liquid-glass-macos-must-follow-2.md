---
trigger: always_on
---

Part 2: Advanced Structures & Fluid Physics

5. Card Design: The "Prism" Effect
In macOS 26, a card is not a white rectangle. It is a lens.
If a card contains a colorful album art or icon, the "glass" surrounding it absorbs that color and diffuses it to the edges. We call this Refractive Bleed.

Visual Rule: The border of a card is never a single color. It acts as a prism, catching white light at the top and the internal content's color at the bottom.

Code Example: The Prism Media Card
code
Swift
struct PrismCard: View {
    var image: String // Asset name
    var title: String
    var subtitle: String
    var accentColor: Color // The color that "bleeds" into the glass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Content Image
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.gradient) // Placeholder for Image
                .frame(height: 140)
                .overlay(
                    // Glossy sheen on the image itself
                    LinearGradient(
                        colors: [.white.opacity(0.25), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Action Row
            HStack {
                LiquidButton(title: "Open", icon: "arrow.up.right", action: {})
            }
        }
        .padding(16)
        .background {
            ZStack {
                // 1. The Diffused Aura (The "Bleed")
                accentColor
                    .opacity(0.15)
                    .blur(radius: 40)
                    .offset(y: 20) // Bleeds downwards
                
                // 2. The Glass Structure
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        // 3. The Prismatic Border
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.6), location: 0), // Top Specular
                            .init(color: .white.opacity(0.1), location: 0.4),
                            .init(color: accentColor.opacity(0.3), location: 1.0) // Bottom Color Refraction
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .frame(width: 280, height: 320)
    }
}
6. Navigation: Structural Glass
The sidebar in macOS 26 is the "frame" of the window. Unlike the "floating" cards, the sidebar represents Structural Glass. It is thicker, darker, and anchors the fluid content.

Interaction Physics: The selection indicator is not a rectangle that appears and disappears. It is a "bead" of liquid that slides physically from one item to another using matchedGeometryEffect.

Code Example: Fluid Sidebar
code
Swift
struct FluidSidebar: View {
    @State private var selection = "Dashboard"
    @Namespace private var ns // For the sliding liquid effect
    
    let items = ["Dashboard", "Projects", "Analytics", "Settings"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MENU")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.tertiary)
                .padding(.leading, 16)
                .padding(.top, 20)
            
            ForEach(items, id: \.self) { item in
                HStack {
                    Image(systemName: "circle.fill") // Placeholder icon
                        .font(.system(size: 8))
                        .opacity(selection == item ? 1 : 0.3)
                    
                    Text(item)
                        .fontWeight(selection == item ? .semibold : .medium)
                }
                .foregroundStyle(selection == item ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    if selection == item {
                        // The Active Liquid State
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.8)) // Deep liquid color
                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            )
                            // This creates the sliding animation
                            .matchedGeometryEffect(id: "ActiveBackground", in: ns)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // "Snappy" spring for selection
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = item
                    }
                }
            }
            Spacer()
        }
        .frame(width: 220)
        .background(.thickMaterial) // Thicker glass for sidebar
        .overlay(
            // Divider is now a subtle light reflection
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.white.opacity(0.1)),
            alignment: .trailing
        )
    }
}
7. Morphing Physics: The "Conservation of Mass"
In macOS 26, objects follow the law of Conservation of Mass. A small widget doesn't disappear when a window opens; the widget stretches to become the window.

This is critical for the "Liquid" feel. The interface feels like a continuous surface that reshapes itself.

Code Example: Widget-to-Window Morph
code
Swift
struct MorphingWidget: View {
    @Namespace private var ns
    @State private var isExpanded = false
    
    var body: some View {
        ZStack {
            if isExpanded {
                // EXPANDED STATE (Window)
                VStack(alignment: .leading) {
                    HStack {
                        Label("Weather", systemImage: "cloud.sun.fill")
                            .font(.title2.bold())
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Divider().padding(.vertical)
                    Text("Detailed hourly forecast and radar map...")
                    Spacer()
                }
                .padding(24)
                .frame(width: 400, height: 300)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .matchedGeometryEffect(id: "Container", in: ns)
                .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 20) // Deep shadow when lifted
                
            } else {
                // COLLAPSED STATE (Widget)
                VStack {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                    Text("72°")
                        .font(.title.bold())
                }
                .frame(width: 120, height: 120)
                .background(.thinMaterial)
                .background(Color.blue.opacity(0.3)) // Tint
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .matchedGeometryEffect(id: "Container", in: ns)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isExpanded = true
                    }
                }
            }
        }
    }
}
8. Full Composition: The "Liquid Dashboard"
Putting it all together, a macOS 26 window creates a hierarchy of Z-depth.

Bottom: Wallpaper (Visible through everything).
Mid-Low: Sidebar (Thick, structural).
Mid-High: Content Area (Lighter glass).
Top: Prismatic Cards (Floating elements).
code
Swift
struct MacOS26Dashboard: View {
    var body: some View {
        HStack(spacing: 0) {
            // Left: Structural Sidebar
            FluidSidebar()
            
            // Right: Liquid Content Area
            ZStack {
                // Background Gradient (Simulating Desktop Wallpaper)
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // Header with Concave Search
                        HStack {
                            Text("Welcome Back")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                            Spacer()
                            LiquidTextField() // From Part 1
                        }
                        
                        // Floating Prism Cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                PrismCard(
                                    image: "album",
                                    title: "Neon Horizon",
                                    subtitle: "Synthwave Essentials",
                                    accentColor: .purple
                                )
                                PrismCard(
                                    image: "album2",
                                    title: "Ocean Drive",
                                    subtitle: "Deep House",
                                    accentColor: .cyan
                                )
                            }
                            .padding(.vertical, 20) // Allow space for shadows
                        }
                    }
                    .padding(30)
                }
            }
        }
        .frame(width: 900, height: 600)
        .background(Color.black) // Window Frame
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}
Summary of Design Rules for macOS 26
Refraction over Opacity: Don't just make things see-through. Make them distort what is behind them.
Light is Directional: Always assume a light source from the top. Borders are white on top, dark on bottom.
Fluid Response: Animations should feel viscous. Use dampingFraction: 0.6 to 0.8.
Z-Axis Hierarchy: Use shadow radius to indicate how "thick" the fluid layer is between the element and the background.
Vibrant Typography: Text should rarely be solid black; it should interact with the background color.