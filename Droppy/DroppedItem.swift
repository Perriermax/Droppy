//
//  DroppedItem.swift
//  Droppy
//
//  Created by Jordy Spruit on 02/01/2026.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLookThumbnailing
import AppKit

/// Represents a file or item dropped onto the Droppy shelf
struct DroppedItem: Identifiable, Hashable, Transferable {
    let id = UUID()
    let url: URL
    let name: String
    let fileType: UTType?
    let icon: NSImage
    var thumbnail: NSImage?
    let dateAdded: Date
    
    // Conformance to Transferable using the URL as a proxy
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.url)
    }
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.fileType = UTType(filenameExtension: url.pathExtension)
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
        self.dateAdded = Date()
        self.thumbnail = nil
    }
    
    /// Generates a thumbnail for the file asynchronously
    func generateThumbnail(size: CGSize = CGSize(width: 64, height: 64)) async -> NSImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: NSScreen.main?.backingScaleFactor ?? 2.0,
            representationTypes: .thumbnail
        )
        
        do {
            let thumbnail = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            return thumbnail.nsImage
        } catch {
            return icon
        }
    }
    
    /// Copies the file to the clipboard (with actual content for images)
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // For images, copy the actual image data so it pastes into apps like Outlook
        if let fileType = fileType, fileType.conforms(to: .image) {
            if let image = NSImage(contentsOf: url) {
                pasteboard.writeObjects([image])
                // Also add file URL as fallback
                pasteboard.writeObjects([url as NSURL])
                return
            }
        }
        
        // For PDFs, copy both PDF data and file reference
        if let fileType = fileType, fileType.conforms(to: .pdf) {
            if let pdfData = try? Data(contentsOf: url) {
                pasteboard.setData(pdfData, forType: .pdf)
            }
            pasteboard.writeObjects([url as NSURL])
            return
        }
        
        // For text files, copy the text content directly
        if let fileType = fileType, fileType.conforms(to: .plainText) {
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                pasteboard.setString(text, forType: .string)
            }
            pasteboard.writeObjects([url as NSURL])
            return
        }
        
        // Default: copy file URL
        pasteboard.writeObjects([url as NSURL])
    }
    
    /// Opens the file with the default application
    func openFile() {
        NSWorkspace.shared.open(url)
    }
    
    /// Reveals the file in Finder
    func revealInFinder() {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
    
    /// Saves the file directly to the user's Downloads folder
    /// Returns the URL of the saved file if successful
    @MainActor
    @discardableResult
    func saveToDownloads() -> URL? {
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        var destinationURL = downloadsURL.appendingPathComponent(name)
        
        // Handle duplicate filenames
        var counter = 1
        let fileNameWithoutExtension = destinationURL.deletingPathExtension().lastPathComponent
        let fileExtension = destinationURL.pathExtension
        
        while FileManager.default.fileExists(atPath: destinationURL.path) {
            let newName = "\(fileNameWithoutExtension) \(counter)"
            destinationURL = downloadsURL.appendingPathComponent(newName).appendingPathExtension(fileExtension)
            counter += 1
        }
        
        do {
            try FileManager.default.copyItem(at: self.url, to: destinationURL)
            
            // Visual feedback: Bounce the dock icon
            NSApplication.shared.requestUserAttention(.informationalRequest)
            
            // Select in Finder so the user knows where it is
            NSWorkspace.shared.selectFile(destinationURL.path, inFileViewerRootedAtPath: downloadsURL.path)
            
            return destinationURL
        } catch {
            print("Error saving to downloads: \(error)")
            return nil
        }
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DroppedItem, rhs: DroppedItem) -> Bool {
        lhs.id == rhs.id
    }
}

