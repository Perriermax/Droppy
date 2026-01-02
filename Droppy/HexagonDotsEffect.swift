//
//  HexagonDotsEffect.swift
//  Droppy
//
//  Created by Jordy Spruit on 02/01/2026.
//

import SwiftUI

// MARK: - Hexagon Dots Effect
struct HexagonDotsEffect: View {
    var isExpanded: Bool = false
    var mouseLocation: CGPoint
    var isHovering: Bool
    var coordinateSpaceName: String = "shelfContainer"
    
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                // Coordinate transformation:
                // mouseLocation is in the named coordinate space.
                // We need to convert it to local space.
                let myFrame = proxy.frame(in: .named(coordinateSpaceName))
                let localMouse = CGPoint(
                    x: mouseLocation.x - myFrame.minX,
                    y: mouseLocation.y - myFrame.minY
                )
                
                let spacing: CGFloat = 8 // Much tinier spacing
                let radius: CGFloat = 0.8 // Much smaller dots
                let hexHeight = spacing * sqrt(3) / 2
                
                let cols = Int(size.width / spacing) + 2
                let rows = Int(size.height / hexHeight) + 2
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let xOffset = (row % 2 == 0) ? 0 : spacing / 2
                        let x = CGFloat(col) * spacing + xOffset
                        let y = CGFloat(row) * hexHeight
                        
                        let point = CGPoint(x: x, y: y)
                        let distance = sqrt(pow(point.x - localMouse.x, 2) + pow(point.y - localMouse.y, 2))
                        
                        // Effect logic
                        let limit: CGFloat = 80 // Slightly tighter radius
                        if isHovering && distance < limit {
                            let intensity = 1 - (distance / limit) // 0 to 1
                            
                            // Scale up
                            let scale = 1 + (intensity * 0.5) // Reduced scale even further (was 0.8)
                            
                            // Opacity boost
                            // Base 0.02, Max around 0.15 - MUCH more faded
                            let opacity = 0.02 + (intensity * 0.13)
                            
                            let rect = CGRect(
                                x: x - radius * scale,
                                y: y - radius * scale,
                                width: radius * 2 * scale,
                                height: radius * 2 * scale
                            )
                            
                            context.opacity = opacity
                            context.fill(Circle().path(in: rect), with: .color(.white))
                            
                        } else {
                            // Base state
                            context.opacity = 0.015 // Extremely subtle base opacity (was 0.04)
                            let rect = CGRect(
                                x: x - radius,
                                y: y - radius,
                                width: radius * 2,
                                height: radius * 2
                            )
                            context.fill(Circle().path(in: rect), with: .color(.white))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false) // Purely visual
    }
}
