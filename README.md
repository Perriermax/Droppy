<p align="center">
  <img src="https://i.postimg.cc/PxdpGc3S/appstore.png" alt="Droppy Icon" width="128">
</p>

<h1 align="center">Droppy</h1>

<p align="center">
  <strong>The ultimate drag-and-drop file shelf for macOS.</strong><br>
  <em>"It feels like it should have been there all along."</em>
</p>

<p align="center">
    <img src="https://img.shields.io/github/v/release/iordv/Droppy?style=flat-square&color=007AFF" alt="Latest Release">
    <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="Platform">
    <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License">
</p>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#features">Features</a> •
  <a href="#usage">Usage</a>
</p>

---

## What is Droppy?

Droppy provides a **temporary shelf** for your files. Drag files to the top of your screen (the Notch) or "jiggle" your mouse to summon a Basket right where you are. It's the perfect holding zone when moving files between apps, spaces, or folders.

🚀 **Version 2.3.0 is here!** Better compression, smarter handling, and pure polish.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| **🗂️ Notch Shelf** | Drag files to the Notch. They vanish into a sleek shelf, ready when you are. |
| **🧺 Floating Basket** | **"Jiggle" your mouse** while dragging to summon a basket instantly at your cursor. |
| **📉 Smart Compression** | Right-click to compress Images, PDFs, and Videos. Now with **Size Guard** 🛡️ to prevent bloat. |
| **⚡️ Fast Actions** | Convert images/docs, extract text (OCR), zip, or rename directly from the shelf. |
| **🖥️ Multi-Monitor** | Works beautifully on external displays. Auto-hides the visual notch if you prefer. |

---

## 🎨 Visual Tour

### The Notch Shelf
*Perfect for MacBook users. Utilizes the empty space around your webcam.*
<p align="center">
  <img src="https://i.postimg.cc/63TpswW4/image.png" alt="Notch Shelf Preview" width="100%">
</p>

### The Floating Basket
*For everyone else. Just give your cursor a little shake.*
<p align="center">
  <img src="https://i.postimg.cc/50488cNj/image.png" alt="Floating Basket Preview" width="100%">
</p>

---

## 🛠️ Power User Tools

### 📉 Intelligent Compression (New in v2.3)
Droppy doesn't just squash files; it optimizes them.
- **Smart Defaults**: "Auto" uses HEVC for videos (1080p) and balanced settings for images.
- **Target Size**: Need a JPEG under 2MB? Right-click → Compress → **Target Size...** and tell it exactly what you need.
- **Size Guard**: If compression would make the file larger (common with some PDFs), Droppy **shakes no** and pulses a Green Shield 🛡️ to let you know it kept the original.

### 📝 Drag-and-Drop OCR
Need text from an image?
1. Drag an image into Droppy.
2. Hold **Shift** while dragging it out.
3. Drop it into a text editor. **Boom. It's text.**

---

## 📥 Installation

### Option 1: Homebrew (Recommended)
Updates are easy.
```bash
brew install --cask iordv/tap/droppy
```

### Option 2: Manual Download
1. Download [**Droppy.dmg**](https://github.com/iordv/Droppy/raw/main/Droppy.dmg).
2. Drag to Applications.
3. **Right-click → Open** on first launch.

> **Note**: If macOS says the app is damaged (Quarantine issue):
> ```bash
> xattr -d com.apple.quarantine /Applications/Droppy.app
> ```

---

## 🆕 What's New
<!-- CHANGELOG_START -->
# Features
- **Simplified Compression**: Removed complex settings. "Auto (Medium)" is now the default.
- **Photos Target Size**: Right-click images to specify exact MB size.
- **Smart Size Guard**: Automatically cancels compression if the file doesn't get smaller.
- **Visual Feedback**: "Shake & Shield" animation confirms optimal compression.
- **Better Video**: Now uses HEVC 1080p for high-definition, small-size results.
- **External Displays**: Option to hide the Notch on external monitors.

# Improvements
- Fixed PDF page orientation issues.
- Fixed Video compression size increase issues.
<!-- CHANGELOG_END -->

---

## License
MIT License. Free and Open Source forever.
Made with ❤️ by [Jordy Spruit](https://github.com/iordv).
