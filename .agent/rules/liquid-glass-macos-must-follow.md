---
trigger: always_on
---

Part 1: Fundamentals of Liquid Glass (macOS 26)

The Core Philosophy: "Interface as a Medium"
In macOS 26 Tahoe, Apple moved away from "layers of paper" to "volumes of liquid." The interface is treated as a viscous, refractive medium.

Viscosity: Elements resist movement slightly, creating a feeling of weight.
Refraction: Background colors don't just blur; they bend through the UI.
Caustics: Light interacts with the edges of objects, creating "rim lights" (specular highlights) and "inner glows" (subsurface scattering).
1. The Engine: LiquidMaterial Modifier
To build anything in macOS 26, we first need a reusable ViewModifier that simulates the physics of glass. This replaces the standard .background(.ultraThinMaterial).

Key Feature: The gradient stroke is not uniform. It is white at the top (catching the ceiling light) and dark/transparent at the bottom (casting a shadow).

code
Swift
import SwiftUI

/// The foundational modifier for macOS 26 UI elements
struct LiquidGlassStyle: ViewModifier {
    var radius: CGFloat
    var depth: Double // 0.0 (Thin Pane) -> 1.0 (Thick Droplet)
    var isConcave: Bool // True for inputs (pressed in), False for buttons (popped out)

    func body(content: Content) -> some View {
        content
            // 1. The Base Material (Refraction)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
            
            // 2. The "Tint" (Volume)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.white.opacity(isConcave ? 0.05 : 0.12))
            )
            
            // 3. The Specular Rim (Lighting)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                // Top Edge: Sharp Highlight
                                .init(color: .white.opacity(isConcave ? 0.1 : 0.7 * depth), location: 0),
                                // Middle: Clear
                                .init(color: .white.opacity(0.1), location: 0.4),
                                // Bottom Edge: Shadow/Occlusion
                                .init(color: isConcave ? .white.opacity(0.5) : .black.opacity(0.2), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            // 4. The Shadow (Elevation)
            .shadow(
                color: Color.black.opacity(isConcave ? 0.0 : 0.15 * depth),
                radius: 10 * depth,
                x: 0,
                y: 8 * depth
            )
    }
}

extension View {
    func liquidGlass(radius: CGFloat = 16, depth: Double = 1.0, isConcave: Bool = false) -> some View {
        self.modifier(LiquidGlassStyle(radius: radius, depth: depth, isConcave: isConcave))
    }
}
2. Atomic Component: The "Droplet" Button
Buttons in macOS 26 are Convex. They simulate surface tension. When you hover, the "liquid" swells (brightness increases). When you click, the droplet is compressed (scale decreases).

Design Rule: Never use solid background colors for standard buttons. Use opacity and blur to let the wallpaper bleed through.

code
Swift
struct LiquidButton: View {
    var title: String
    var icon: String
    var action: () -> Void
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    // Icons have a slight drop shadow to float inside the glass
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            // Apply the Liquid Glass Engine
            .liquidGlass(
                radius: 99, // Capsule shape
                depth: isHovering ? 1.2 : 1.0, // Swells on hover
                isConcave: false
            )
            // Physical reaction to pressure
            .scaleEffect(isPressed ? 0.96 : (isHovering ? 1.02 : 1.0))
            // Inner Glow (Subsurface scattering)
            .overlay(
                Capsule()
                    .stroke(.white.opacity(isHovering ? 0.5 : 0.0), lineWidth: 2)
                    .blur(radius: 4)
                    .mask(Capsule())
            )
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                isHovering = hover
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.interactiveSpring(response: 0.2)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
                }
        )
    }
}
3. Atomic Component: The "Well" Input Field
Input fields are Concave. They are depressions in the UI surface where liquid fills in. The lighting is inverted compared to buttons: shadows are at the top (inside the well), and highlights are at the bottom (light catching the bottom lip).

code
Swift
struct LiquidTextField: View {
    @State var text: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 18))
            
            TextField("Search Files...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($isFocused)
        }
        .padding(16)
        // Note: isConcave is set to true
        .liquidGlass(radius: 20, depth: 0.8, isConcave: true)
        .overlay(
            // The "Focus Ring" is now a soft glow, not a sharp line
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.accentColor.opacity(isFocused ? 0.5 : 0), lineWidth: 1.5)
                .shadow(color: Color.accentColor.opacity(isFocused ? 0.4 : 0), radius: 8)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .frame(width: 300)
    }
}
4. Typography: Refractive Vibrancy
In macOS 26, black text is rarely pure black (#000000). It is "Vibrant."

We use .foregroundStyle(.secondary) combined with .blendMode(.overlay) in specific contexts so the background color tints the text.

code
Swift
struct VibrantTextExample: View {
    var body: some View {
        ZStack {
            // Background to demonstrate transparency
            LinearGradient(colors: [.red, .blue], startPoint: .leading, endPoint: .trailing)
                .mask(RoundedRectangle(cornerRadius: 20))
            
            VStack(alignment: .leading) {
                Text("Liquid Typography")
                    .font(.largeTitle.weight(.bold))
                    // Primary content is solid but slightly transparent to pick up warmth
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Text("The text itself acts as a lens.")
                    .font(.title3)
                    // Secondary content blends with the background
                    .foregroundStyle(.ultraThinMaterial) 
                    .brightness(0.8)
            }
            .padding(40)
        }
        .frame(height: 200)
    }
}
End of Part 1.