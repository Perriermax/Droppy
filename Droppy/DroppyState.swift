//
//  DroppyState.swift
//  Droppy
//
//  Created by Jordy Spruit on 02/01/2026.
//

import SwiftUI
import Observation

/// Main application state for the Droppy shelf
@Observable
final class DroppyState {
    /// Items currently on the shelf
    var items: [DroppedItem] = []
    
    /// Whether the shelf is currently visible
    var isShelfVisible: Bool = false
    
    /// Currently selected items for bulk operations
    var selectedItems: Set<UUID> = []
    
    /// Position where the shelf should appear (near cursor)
    var shelfPosition: CGPoint = .zero
    
    /// Whether the drop zone is currently targeted (hovered with files)
    var isDropTargeted: Bool = false
    
    /// Whether the mouse is hovering over the notch (no files)
    var isMouseHovering: Bool = false
    
    /// Whether the shelf is expanded to show items (Notch View)
    var isExpanded: Bool = false
    
    /// Pending converted file ready to download (temp URL, original filename)
    var pendingConversion: (tempURL: URL, filename: String)?
    
    /// Shared instance for app-wide access
    static let shared = DroppyState()
    
    private init() {}
    
    // MARK: - Item Management
    
    /// Adds a new item to the shelf
    func addItem(_ item: DroppedItem) {
        // Avoid duplicates
        guard !items.contains(where: { $0.url == item.url }) else { return }
        items.append(item)
    }
    
    /// Adds multiple items from file URLs
    func addItems(from urls: [URL]) {
        for url in urls {
            let item = DroppedItem(url: url)
            addItem(item)
        }
    }
    
    /// Removes an item from the shelf
    func removeItem(_ item: DroppedItem) {
        items.removeAll { $0.id == item.id }
        selectedItems.remove(item.id)
    }
    
    /// Removes selected items
    func removeSelectedItems() {
        items.removeAll { selectedItems.contains($0.id) }
        selectedItems.removeAll()
    }
    
    /// Clears all items from the shelf
    func clearAll() {
        items.removeAll()
        selectedItems.removeAll()
    }
    
    // MARK: - Selection
    
    /// Toggles selection for an item
    func toggleSelection(_ item: DroppedItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }
    
    /// Selects all items
    func selectAll() {
        selectedItems = Set(items.map { $0.id })
    }
    
    /// Deselects all items
    func deselectAll() {
        selectedItems.removeAll()
    }
    
    // MARK: - Clipboard
    
    /// Copies all selected items (or all items if none selected) to clipboard
    func copyToClipboard() {
        let itemsToCopy = selectedItems.isEmpty 
            ? items 
            : items.filter { selectedItems.contains($0.id) }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(itemsToCopy.map { $0.url as NSURL })
    }
    
    // MARK: - Shelf Visibility
    
    /// Shows the shelf at the specified position
    func showShelf(at position: CGPoint) {
        shelfPosition = position
        isShelfVisible = true
    }
    
    /// Hides the shelf
    func hideShelf() {
        isShelfVisible = false
    }
    
    /// Toggles shelf visibility
    func toggleShelf() {
        isShelfVisible.toggle()
    }
}
