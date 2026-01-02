//
//  DragMonitor.swift
//  Droppy
//
//  Created by Jordy Spruit on 02/01/2026.
//

import AppKit
import Combine

/// Monitors system-wide drag events to detect when files/items are being dragged
final class DragMonitor: ObservableObject {
    /// Shared instance for app-wide access
    static let shared = DragMonitor()
    
    /// Whether a drag operation with droppable content is in progress
    @Published private(set) var isDragging = false
    
    /// The current mouse location during drag
    @Published private(set) var dragLocation: CGPoint = .zero
    
    private var dragCheckTimer: Timer?
    private var dragStartChangeCount: Int = 0
    private var dragActive = false
    
    private init() {}
    
    /// Starts monitoring for drag events
    func startMonitoring() {
        // Monitor the drag pasteboard for content
        dragCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.checkForActiveDrag()
        }
    }
    
    /// Stops monitoring for drag events
    func stopMonitoring() {
        dragCheckTimer?.invalidate()
        dragCheckTimer = nil
    }
    
    private func checkForActiveDrag() {
        let dragPasteboard = NSPasteboard(name: .drag)
        let currentChangeCount = dragPasteboard.changeCount
        let mouseIsDown = NSEvent.pressedMouseButtons & 1 != 0
        
        // Detect drag START: pasteboard change count increased and mouse is down
        if currentChangeCount != dragStartChangeCount && mouseIsDown {
            let hasContent = dragPasteboard.types?.isEmpty == false
            if hasContent && !dragActive {
                // New drag started
                dragActive = true
                dragStartChangeCount = currentChangeCount
                DispatchQueue.main.async { [weak self] in
                    self?.isDragging = true
                    self?.dragLocation = NSEvent.mouseLocation
                }
            }
        }
        
        // Keep updating location while drag is active
        if dragActive && mouseIsDown {
            DispatchQueue.main.async { [weak self] in
                self?.dragLocation = NSEvent.mouseLocation
            }
        }
        
        // Detect drag END: mouse released
        if !mouseIsDown && dragActive {
            dragActive = false
            DispatchQueue.main.async { [weak self] in
                self?.isDragging = false
            }
        }
    }
}
