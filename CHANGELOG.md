# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-12-27

### Added
- **FFmpeg Video Export**: Convert `.cast` recordings to GIF, MP4, and WebM
  - Pure Ruby PPM frame renderer with embedded 8x16 VGA bitmap font
  - 2-pass palette optimization for high-quality GIF output
  - H.264 encoding for MP4 (libx264, yuv420p, CRF 23)
  - VP9 encoding for WebM (libvpx-vp9, CRF 30)
- **New CLI Options**: `--fps`, `--theme`, `--scale` for video export
- **Video Export Test Suite**: `examples/video_export_test.rb` with comprehensive edge case testing

### Fixed
- **Rich::Tree markup rendering**: Labels with markup like `[blue]text[/]` now correctly parse to ANSI escape codes instead of rendering as literal text
- **Unicode characters in video export**: Added block elements (█ ░ ▒ ▓), box-drawing characters, and symbols (✓ ✗ ▶) to embedded font for proper progress bar and table rendering

### Changed
- Updated gemspec description with video export capabilities
- Updated README with video export documentation

### Dependencies
- FFmpeg required for video export (optional, native formats work without it)

## [0.1.0] - 2025-12-24

### Initial Release
- Native Windows terminal recording with Win32 Console APIs
- Asciicast v2 format support (compatible with asciinema.org)
- Export formats: HTML, SVG, Text, JSON
- 9 terminal themes (asciinema, dracula, monokai, nord, tokyo-night, etc.)
- Rich-Ruby integration for beautiful terminal formatting
- Speed adjustment and idle compression
- Recording concatenation
- Thumbnail generation
- Zero external dependencies for core functionality
