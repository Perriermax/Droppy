//
//  NotchShelfView.swift
//  Droppy
//
//  Created by Jordy Spruit on 02/01/2026.
//

import SwiftUI
import UniformTypeIdentifiers

/// The notch-based shelf view that shows a yellow glow during drag and expands to show items
struct NotchShelfView: View {
    @Bindable var state: DroppyState
    @ObservedObject var dragMonitor = DragMonitor.shared
    @AppStorage("useTransparentBackground") private var useTransparentBackground = false
    
    
    /// Animation state for the border dash
    @State private var dashPhase: CGFloat = 0
    @State private var dropZoneDashPhase: CGFloat = 0
    
    // Marquee Selection State
    @State private var selectionRect: CGRect? = nil
    @State private var initialSelection: Set<UUID> = []
    @State private var itemFrames: [UUID: CGRect] = [:]
    
    // Background Hover Effect State
    @State private var hoverLocation: CGPoint = .zero
    @State private var isBgHovering: Bool = false
    
    // Removed isDropTargeted state as we use shared state now
    
    /// Real MacBook notch dimensions
    private let notchWidth: CGFloat = 180
    private let notchHeight: CGFloat = 32
    private let expandedWidth: CGFloat = 450
    // Dynamic height based on row count
    private var currentExpandedHeight: CGFloat {
        let rowCount = (Double(state.items.count) / 5.0).rounded(.up)
        return max(1, rowCount) * 110 + 40 // 110 per row + 40 header
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Main Morphing Background
            // This is the persistent black shape that grows/shrinks
            NotchShape(bottomRadius: state.isExpanded ? 20 : 16)
                .fill(useTransparentBackground ? Color.clear : Color.black)
                .frame(
                    width: state.isExpanded ? expandedWidth : ((dragMonitor.isDragging || state.isMouseHovering) ? notchWidth + 20 : notchWidth),
                    height: state.isExpanded ? currentExpandedHeight : ((dragMonitor.isDragging || state.isMouseHovering) ? notchHeight + 40 : notchHeight)
                )
                .background {
                    if useTransparentBackground {
                        Color.clear
                            .glassEffect(.regular)
                            .clipShape(NotchShape(bottomRadius: state.isExpanded ? 20 : 16))
                    }
                }
                .overlay {
                    HexagonDotsEffect(
                        isExpanded: state.isExpanded,
                        mouseLocation: hoverLocation,
                        isHovering: isBgHovering
                    )
                    .clipShape(NotchShape(bottomRadius: state.isExpanded ? 20 : 16))
                }
                // Add glow only when dragging and not expanded
                .shadow(radius: 0) // Ensure no shadow interferes
                .overlay(
                   NotchOutlineShape(bottomRadius: state.isExpanded ? 20 : 16)
                       .trim(from: 0, to: 1) // Ensures full path
                       .stroke(
                           style: StrokeStyle(
                               lineWidth: 2,
                               lineCap: .round,
                               lineJoin: .round,
                               dash: [3, 5],
                               dashPhase: dashPhase
                           )
                       )
                       .foregroundStyle(Color.blue)
                       .opacity((!state.isExpanded && (dragMonitor.isDragging || state.isMouseHovering)) ? 1 : 0)
                       .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragMonitor.isDragging)
                       .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.isMouseHovering)
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: state.isExpanded)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragMonitor.isDragging)
                // Animate height changes when items are added/removed
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: state.items.count)
            
            // MARK: - Content Overlay
            ZStack {
                // Always have the drop zone / interaction layer at the top
                dropZone
                    .zIndex(1)
                
                if state.isExpanded {
                    expandedShelfContent
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .frame(width: expandedWidth, height: currentExpandedHeight)
                        .clipShape(NotchShape(bottomRadius: 20))
                        .zIndex(2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: state.items.count) { oldCount, newCount in
             if newCount > oldCount && !state.isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    state.isExpanded = true
                }
            }
             if newCount == 0 && state.isExpanded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    state.isExpanded = false
                }
            }
        }
        // Conversion complete toast
        .overlay(alignment: .bottom) {
            if state.pendingConversion != nil {
                conversionToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 60)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: state.pendingConversion != nil)
        .coordinateSpace(name: "shelfContainer")
        .onContinuousHover(coordinateSpace: .named("shelfContainer")) { phase in
            switch phase {
            case .active(let location):
                hoverLocation = location
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isBgHovering = true
                }
            case .ended:
                withAnimation(.linear(duration: 0.2)) {
                    isBgHovering = false
                }
            }
        }

    }
    
    // MARK: - Glow Effect
    
    // Old glowEffect removed

    
    // MARK: - Drop Zone
    
    private var dropZone: some View {
        // Dynamic hit area: tiny in idle, larger when active
        // This prevents blocking Safari URL bars, Outlook search fields, etc.
        let isActive = state.isExpanded || state.isMouseHovering || dragMonitor.isDragging || state.isDropTargeted
        
        // Idle: just the notch itself (small area that doesn't extend below menu bar)
        // Active: larger area for comfortable interaction
        let dropAreaWidth: CGFloat = isActive ? (notchWidth + 80) : notchWidth
        let dropAreaHeight: CGFloat = isActive ? (notchHeight + 50) : notchHeight
        
        return ZStack {
            // Invisible hit area for hovering/clicking - SIZE CHANGES based on state
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)
                .frame(width: dropAreaWidth, height: dropAreaHeight)
                .contentShape(Rectangle()) // Only THIS rectangle is interactive
            
            // Beautiful drop indicator when hovering with files
            if state.isDropTargeted && !state.isExpanded {
                dropIndicator
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .allowsHitTesting(false) // Don't let the badge capture clicks
            }
            // "Open Shelf" indicator when hovering with mouse (no drag)
            else if state.isMouseHovering && !dragMonitor.isDragging && !state.isExpanded {
                openIndicator
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .allowsHitTesting(false) // Don't let the badge capture clicks
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                state.isExpanded.toggle()
            }
        }
        .onHover { isHovering in
            // Only update hover state if not dragging (drag state handles its own)
            if !dragMonitor.isDragging {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    state.isMouseHovering = isHovering
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.isDropTargeted)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.isMouseHovering)
    }
    
    // MARK: - Indicators
    
    private var dropIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white, .green)
                .symbolEffect(.bounce, value: state.isDropTargeted)
            
            Text("Drop!")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .shadow(radius: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(indicatorBackground)
        .offset(y: notchHeight + 50)
    }
    
    private var openIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white, .blue)
                .symbolEffect(.bounce, value: state.isMouseHovering)
            
            Text("Open Shelf")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .shadow(radius: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(indicatorBackground)
        .background(indicatorBackground)
        .offset(y: notchHeight + 50)
    }
    
    private var indicatorBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
    
    // MARK: - Conversion Toast
    
    private var conversionToast: some View {
        HStack(spacing: 12) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Conversion complete!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                if let pending = state.pendingConversion {
                    Text(pending.filename)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Save to Downloads button
            Button {
                saveToDownloads()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 14))
                    Text("Save")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
            }
            .buttonStyle(.plain)
            
            // Dismiss button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    state.pendingConversion = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(6)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(indicatorBackground)
        .frame(maxWidth: 380)
    }
    
    private func saveToDownloads() {
        guard let pending = state.pendingConversion else { return }
        
        if let savedURL = FileConverter.saveToDownloads(pending.tempURL) {
            // Reveal in Finder for convenience
            NSWorkspace.shared.selectFile(savedURL.path, inFileViewerRootedAtPath: savedURL.deletingLastPathComponent().path)
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            state.pendingConversion = nil
        }
    }

    // MARK: - Expanded Content
    
    private var expandedShelfContent: some View {
        VStack(spacing: 0) {
            // Header / Controls
            HStack(spacing: 0) {
                // Close button
                NotchControlButton(icon: "chevron.up") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        state.isExpanded = false
                    }
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // Clear button
                if !state.items.isEmpty {
                    NotchControlButton(icon: "trash") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            state.clearAll()
                        }
                    }
                    .padding(.trailing, 16)
                }
            }
            .frame(height: 40)
            .frame(width: expandedWidth)
            .contentShape(Rectangle()) // Make header clickable to deselect if needed, or just let it pass
            .onTapGesture {
                state.deselectAll()
            }
            
            // Grid Items
            if state.items.isEmpty {
                emptyShelfContent
                    .frame(height: currentExpandedHeight - 40)
            } else {
                itemsGridView
                    .frame(height: currentExpandedHeight - 40)
            }
        }
    }
    
    private var itemsGridView: some View {
        let items = state.items
        let chunkedItems = stride(from: 0, to: items.count, by: 5).map {
            Array(items[$0..<min($0 + 5, items.count)])
        }
        
        return ScrollView(.vertical, showsIndicators: false) {
            ZStack {
                // Background tap handler - acts as a "canvas" to catch clicks
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        state.deselectAll()
                    }
                    // Moved Marquee Drag Gesture HERE so it doesn't conflict with dragging items
                    .gesture(
                         DragGesture(minimumDistance: 1, coordinateSpace: .named("shelfGrid"))
                             .onChanged { value in
                                 // Start selection
                                 if selectionRect == nil {
                                     initialSelection = state.selectedItems
                                     
                                     if !NSEvent.modifierFlags.contains(.command) && !NSEvent.modifierFlags.contains(.shift) {
                                         state.deselectAll()
                                         initialSelection = []
                                     }
                                 }
                                 
                                 let rect = CGRect(
                                     x: min(value.startLocation.x, value.location.x),
                                     y: min(value.startLocation.y, value.location.y),
                                     width: abs(value.location.x - value.startLocation.x),
                                     height: abs(value.location.y - value.startLocation.y)
                                 )
                                 selectionRect = rect
                                 
                                 // Update Selection
                                 var newSelection = initialSelection
                                 for (id, frame) in itemFrames {
                                     if rect.intersects(frame) {
                                         newSelection.insert(id)
                                     }
                                 }
                                 state.selectedItems = newSelection
                             }
                             .onEnded { _ in
                                 selectionRect = nil
                                 initialSelection = []
                             }
                    )
                
                VStack(spacing: 12) {
                    ForEach(Array(chunkedItems.enumerated()), id: \.offset) { index, rowItems in
                        HStack(spacing: 12) {
                            // Center items: add spacer if row is not full?
                            // Actually, plain HStack with spacing centers by default if not strictly aligned leading
                            // But we want "always center".
                            // If we just do HStack, it centers in the container view.
                            ForEach(rowItems) { item in
                                NotchItemView(
                                    item: item,
                                    state: state,
                                    onRemove: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            state.removeItem(item)
                                        }
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity) // Ensures HStack takes full width to center content
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .frame(minHeight: currentExpandedHeight - 40) // Ensure ZStack fills at least the visible area
        }
        .contentShape(Rectangle())
        // Removed .onTapGesture from here to prevent swallowing touches on children
        .overlay(alignment: .topLeading) {
            if let rect = selectionRect {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.blue.opacity(0.2))
                    .stroke(Color.blue.opacity(0.6), lineWidth: 1)
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: rect.minX, y: rect.minY)
                    .allowsHitTesting(false)
            }
        }
        .coordinateSpace(name: "shelfGrid")
        .onPreferenceChange(ItemFramePreferenceKey.self) { frames in
            self.itemFrames = frames
        }
    }
}

// MARK: - Custom Notch Shape
struct NotchShape: Shape {
    var bottomRadius: CGFloat
    
    var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start top left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Top edge (straight)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))
        
        // Bottom Right Corner
        path.addArc(
            center: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY - bottomRadius),
            radius: bottomRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))
        
        // Bottom Left Corner
        path.addArc(
            center: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY - bottomRadius),
            radius: bottomRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Notch Outline Shape
/// Defines the U-shape outline of the notch (without the top edge)
struct NotchOutlineShape: Shape {
    var bottomRadius: CGFloat
    
    var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start Top Right
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))
        
        // Bottom Right Corner
        path.addArc(
            center: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY - bottomRadius),
            radius: bottomRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))
        
        // Bottom Left Corner
        path.addArc(
            center: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY - bottomRadius),
            radius: bottomRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}

// Extension to split up complex view code
extension NotchShelfView {

    private var emptyShelfContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
            
            Text(state.isDropTargeted ? "It tickles! Drop it please" : "Drop files here")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    state.isDropTargeted ? Color.blue : Color.white.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 8], dashPhase: dropZoneDashPhase)
                )
        )
        .padding(EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20))
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                dropZoneDashPhase -= 280 // Multiple of 14 (6+8)
            }
        }
    }
}

// MARK: - Notch Item View

/// Compact item view optimized for the notch shelf
struct NotchItemView: View {
    let item: DroppedItem
    let state: DroppyState
    let onRemove: () -> Void
    
    @State private var thumbnail: NSImage?
    @State private var isHovering = false
    @State private var isConverting = false
    
    var body: some View {
        DraggableArea(
            items: {
                // If this item is selected, drag all selected items.
                // Otherwise, drag only this item.
                if state.selectedItems.contains(item.id) {
                    let selected = state.items.filter { state.selectedItems.contains($0.id) }
                    return selected.map { $0.url as NSURL }
                } else {
                    return [item.url as NSURL]
                }
            },
            onTap: { modifiers in
                // Handle Selection
                if modifiers.contains(.command) {
                    state.toggleSelection(item)
                } else {
                    // Standard click: select this, deselect others
                    // But if it's already selected and we are just clicking it?
                    // Usually: select this one only.
                    state.deselectAll()
                    state.selectedItems.insert(item.id)
                }
            },
            onRightClick: {
                // Select if not selected
                 if !state.selectedItems.contains(item.id) {
                    state.deselectAll()
                    state.selectedItems.insert(item.id)
                }
            },
            selectionSignature: state.selectedItems.hashValue
        ) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // Thumbnail container
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(state.selectedItems.contains(item.id) ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(state.selectedItems.contains(item.id) ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .frame(width: 60, height: 60)
                        .overlay {
                            Group {
                                if let thumbnail = thumbnail {
                                    Image(nsImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Image(nsImage: item.icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .opacity(isConverting ? 0.5 : 1.0)
                        }
                        .overlay {
                            if isConverting {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.white)
                            }
                        }
                    
                    // Remove button on hover
                    if isHovering {
                        Button(action: onRemove) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.9))
                                    .frame(width: 20, height: 20)
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .offset(x: 6, y: -6)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Filename
                Text(item.name)
                    .font(.system(size: 10, weight: state.selectedItems.contains(item.id) ? .bold : .medium))
                    .foregroundColor(state.selectedItems.contains(item.id) ? .white : .white.opacity(0.85))
                    .lineLimit(1)
                    .frame(width: 68) // Slightly wider
                    .padding(.horizontal, 4)
                    .background(
                        state.selectedItems.contains(item.id) ?
                        Capsule().fill(Color.blue) :
                        Capsule().fill(Color.clear)
                    )
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovering && !state.selectedItems.contains(item.id) ? Color.white.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
        .frame(width: 76, height: 96)
        .background {
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ItemFramePreferenceKey.self,
                        value: [item.id: geo.frame(in: .named("shelfGrid"))]
                    )
            }
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button {
                state.copyToClipboard()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                item.openFile()
            } label: {
                Label("Open", systemImage: "arrow.up.forward.square")
            }
            
            Button {
                item.revealInFinder()
            } label: {
                Label("Reveal in Finder", systemImage: "folder")
            }
            
            Button {
                item.saveToDownloads()
            } label: {
                Label("Save", systemImage: "arrow.down.circle")
            }
            
            // Conversion submenu - only show if conversions are available
            let conversions = FileConverter.availableConversions(for: item.fileType)
            if !conversions.isEmpty {
                Divider()
                
                Menu {
                    ForEach(conversions) { option in
                        Button {
                            convertFile(to: option.format)
                        } label: {
                            Label(option.displayName, systemImage: option.icon)
                        }
                    }
                } label: {
                    Label("Convert to...", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                 if state.selectedItems.contains(item.id) {
                     state.removeSelectedItems()
                 } else {
                     onRemove()
                 }
            }) {
                Label("Remove", systemImage: "trash")
            }
        }
        .task {
            thumbnail = await item.generateThumbnail(size: CGSize(width: 120, height: 120))
        }
    }
    }
    
    // MARK: - Conversion
    
    private func convertFile(to format: ConversionFormat) {
        isConverting = true
        
        Task {
            if let convertedURL = await FileConverter.convert(item.url, to: format) {
                // Set pending conversion for download prompt
                let filename = convertedURL.lastPathComponent
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        state.pendingConversion = (tempURL: convertedURL, filename: filename)
                    }
                    isConverting = false
                }
            } else {
                await MainActor.run {
                    isConverting = false
                }
            }
        }
    }
}

// MARK: - Helper Views

struct NotchControlButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 12, height: 12)
                .foregroundColor(.white.opacity(isHovering ? 1.0 : 0.6))
                .padding(8)
                .background(Color.white.opacity(isHovering ? 0.25 : 0.1))
                .clipShape(Circle())
                .scaleEffect(isHovering ? 1.1 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { mirroring in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isHovering = mirroring
            }
        }
    }
}

// MARK: - Preferences for Marquee Selection
struct ItemFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}


