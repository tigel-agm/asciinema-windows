# Examples & Demo Output

This document shows actual terminal output from the demo scripts.

---

## Test Results Summary

### Comprehensive Test Suite (41 tests)

```
╔══════════════════════════════════════════════════════════════╗
║         asciinema-win Comprehensive Test Suite                ║
╚══════════════════════════════════════════════════════════════╝

Session: comprehensive_test_20251224_110023

▶ Module Loading
  ✓ AsciinemaWin module loads
  ✓ Asciicast module loads
  ✓ Recorder class loads
  ✓ Player class loads
  ✓ Export module loads
  ✓ Themes module loads
  ✓ AnsiParser class loads
  ✓ OutputOrganizer module loads
  ✓ VERSION is defined

▶ Rich-Ruby Integration
  ✓ Rich module loads
  ✓ Rich::Console loads
  ✓ Rich::Panel loads
  ✓ Rich::Table loads
  ✓ Rich::Tree loads
  ✓ Rich::Syntax loads
  ✓ Rich::Text loads
  ✓ Rich::Panel renders content
  ✓ Rich::Table renders content
  ✓ Rich::Tree renders content
  ✓ Rich::Syntax renders Ruby code

▶ Terminal Themes
  ✓ Themes.names returns array
  ✓ At least 5 themes available
  ✓ Theme 'asciinema' exists
  ✓ Theme 'dracula' exists
  ✓ Theme 'monokai' exists
  ✓ Theme 'nord' exists
  ✓ Theme 'tokyo-night' exists

▶ Recording with Rich-Ruby
  ✓ Create recording with real Rich output
  ✓ Recording file has content
  ✓ Recording has valid asciicast header

▶ Export Formats
  ✓ Export to SVG (asciinema theme)
  ✓ Export to SVG (dracula theme)
  ✓ Export to HTML
  ✓ Export to JSON
  ✓ Export to Text

▶ Advanced Features
  ✓ Speed adjustment (2x)
  ✓ Thumbnail generation (last frame)
  ✓ Recording concatenation

▶ ANSI Parser
  ✓ AnsiParser parses colors
  ✓ AnsiParser handles cursor movement
  ✓ AnsiParser handles 256 colors

============================================================
Tests: 41, Passed: 41, Failed: 0
============================================================
```

---

### Rich-Ruby Stress Test Suite (51 tests)

```
======================================================================
Rich Library Stress Test Suite
======================================================================

  Parse all 256 ANSI color names                    ... PASS (0.000s)
  Parse 10,000 random hex colors                    ... PASS (0.043s)
  Color downgrade from truecolor to 256             ... PASS (0.005s)
  Color downgrade from truecolor to 16              ... PASS (0.016s)
  ColorTriplet HSL roundtrip                        ... PASS (0.000s)
  Color parse caching performance                   ... PASS (0.126s)
  Parse complex style definitions                   ... PASS (0.000s)
  Style combination chain (1000 styles)             ... PASS (0.008s)
  Style attribute bitmask integrity                 ... PASS (0.000s)
  Style render with all attributes                  ... PASS (0.000s)
  CJK character width calculation                   ... PASS (0.001s)
  Zero-width combining characters                   ... PASS (0.000s)
  Mixed ASCII and Unicode                           ... PASS (0.001s)
  Large Unicode string (10KB)                       ... PASS (0.322s)
  Empty and whitespace strings                      ... PASS (0.000s)
  Segment split at every position                   ... PASS (0.002s)
  Segment line splitting with many newlines         ... PASS (0.000s)
  Segment simplification (1000 segments)            ... PASS (0.001s)
  Segment rendering with control codes              ... PASS (0.000s)
  Text with 1000 overlapping spans                  ... PASS (0.055s)
  Deeply nested markup                              ... PASS (0.000s)
  Markup validation with errors                     ... PASS (0.000s)
  Text wrapping at various widths                   ... PASS (0.125s)
  Text with special characters                      ... PASS (0.000s)
  Panel with very long content                      ... PASS (0.061s)
  Panel with Unicode borders and content            ... PASS (0.001s)
  Table with 100 rows                               ... PASS (0.088s)
  Table with Unicode content                        ... PASS (0.003s)
  Tree with deep nesting (10 levels)                ... PASS (0.000s)
  Tree with many siblings (100)                     ... PASS (0.000s)
  All box styles render correctly                   ... PASS (0.002s)
  Progress bar at every percentage                  ... PASS (0.000s)
  Progress bar with very large total                ... PASS (0.000s)
  Spinner cycles through all frames                 ... PASS (0.002s)
  Multiple spinner styles                           ... PASS (0.000s)
  JSON with deeply nested structure                 ... PASS (0.002s)
  JSON with large array                             ... PASS (0.018s)
  JSON with special characters                      ... PASS (0.000s)
  Pretty print complex Ruby object                  ... PASS (0.001s)
  Console size detection                            ... PASS (0.000s)
  Console options update                            ... PASS (0.000s)
  Control codes generate valid ANSI                 ... PASS (0.000s)
  ANSI stripping                                    ... PASS (0.000s)
  Windows Console API functions available           ... PASS (0.000s)
  Windows ANSI support detection                    ... PASS (0.000s)
  Windows console size valid                        ... PASS (0.000s)
  Empty inputs handled gracefully                   ... PASS (0.000s)
  Nil inputs handled gracefully                     ... PASS (0.000s)
  Very long single-line content                     ... PASS (0.000s)
  Content at exact width boundary                   ... PASS (0.001s)
  Zero and negative values                          ... PASS (0.000s)

======================================================================
Results: 51/51 tests passed in 0.89s
======================================================================
```

---

### asciinema-win Stress Test Suite (26 tests)

```
======================================================================
asciinema-win Stress Test Suite
======================================================================

  Create recording with 10,000 events               ... PASS (0.035s)
  Read recording with 10,000 events                 ... PASS (0.009s)
  Recording with very long lines (10KB each)        ... PASS (0.007s)
  Recording with Unicode content                    ... PASS (0.001s)
  Recording with all ANSI color codes               ... PASS (0.001s)
  Recording with resize events                      ... PASS (0.000s)
  Recording with markers                            ... PASS (0.000s)
  AnsiParser with 1000 lines                        ... PASS (0.123s)
  AnsiParser with complex cursor movement           ... PASS (0.002s)
  AnsiParser with all SGR attributes                ... PASS (0.001s)
  AnsiParser with 256 color palette                 ... PASS (0.003s)
  AnsiParser with RGB colors                        ... PASS (0.000s)
  Export large recording to SVG                     ... PASS (0.827s)
  Export to all 9 themes                            ... PASS (0.024s)
  Export to HTML                                    ... PASS (0.001s)
  Export to JSON                                    ... PASS (0.001s)
  Export to Text                                    ... PASS (0.001s)
  Speed adjustment (0.5x to 4x)                     ... PASS (0.002s)
  Idle compression                                  ... PASS (0.001s)
  Concatenate 10 recordings                         ... PASS (0.003s)
  Thumbnail generation (all frame types)            ... PASS (0.021s)
  Thumbnail at specific time                        ... PASS (0.003s)
  All themes have valid colors                      ... PASS (0.000s)
  Theme ANSI color resolution                       ... PASS (0.000s)
  Create 100 session paths                          ... PASS (0.006s)
  Session summary generation                        ... PASS (0.002s)

======================================================================
Results: 26/26 tests passed in 1.07s
======================================================================
```

---

### Video Export Test Suite (23 tests)

```
══════════════════════════════════════════════════════════════════════
Video Export Test Suite
══════════════════════════════════════════════════════════════════════

▶ FFmpeg Availability
  ✓ FFmpeg is available in PATH
  ✓ FFmpeg version can be detected

▶ GIF Export
  ✓ Export recording to GIF
  ✓ GIF file has valid header
  ✓ GIF with custom FPS (15)

▶ MP4 Export
  ✓ Export recording to MP4
  ✓ MP4 file has valid header (ftyp)
  ✓ MP4 with custom FPS (30)

▶ WebM Export
  ✓ Export recording to WebM
  ✓ WebM file has valid header

▶ Export Options
  ✓ Export with theme: dracula
  ✓ Export with low FPS (2)
  ✓ Export with high FPS (30)

▶ Error Handling
  ✓ Raises error for non-existent input file
  ✓ Raises error for unsupported format

▶ Theme Support
  ✓ Export with theme: asciinema
  ✓ Export with theme: dracula
  ✓ Export with theme: monokai
  ✓ Export with theme: nord
  ✓ Export with theme: tokyo-night

▶ Edge Cases
  ✓ Export minimal recording (single character)
  ✓ Handle recording with no output events gracefully
  ✓ Export to path with spaces

══════════════════════════════════════════════════════════════════════
Results: 23/23 tests passed
══════════════════════════════════════════════════════════════════════
```

---

## Live Rich-Ruby Demo Output

This demo creates recordings with real Rich-Ruby components.

```
╔══════════════════════════════════════════════════════════════╗
║         Live Rich-Ruby Recording Demo                        ║
╚══════════════════════════════════════════════════════════════╝

Session: live_rich_demo_20251224_104855

Rendering Rich-Ruby components...
  → Rich::Panel...
  → Rich::Table...
  → Rich::Tree...
  → Rich::Syntax...
  → All components rendered!

Creating recording: asciinema_output/recordings/live_rich_demo.../demo.cast
✓ Recording complete

Recording info:
  Size: 100x40
  Duration: 15.20s
  Events: 245

Exporting...
  SVG (asciinema)
  SVG (dracula)
  SVG (monokai)
  SVG (tokyo-night)
  SVG (nord)
  SVG (solarized-dark)
  SVG (solarized-light)
  SVG (one-dark)
  SVG (github-dark)
  HTML
  JSON

Generating thumbnails...
  first
  middle
  last

============================================================
Session: live_rich_demo_20251224_104855
Created: 2025-12-24 10:48:55
Outputs:
  recording: demo.cast (12456 bytes)
  svg: demo_asciinema.svg (6943 bytes)
  svg: demo_dracula.svg (6922 bytes)
  ...
============================================================

✓ All exports complete!
```

---

## Output Directory Structure

After running the demos, the output is organized as:

```
asciinema_output/
├── recordings/
│   └── live_rich_demo_20251224_104855/
│       └── demo.cast
├── svg/
│   └── live_rich_demo_20251224_104855/
│       ├── demo_asciinema.svg
│       ├── demo_dracula.svg
│       ├── demo_monokai.svg
│       └── ...
├── html/
│   └── live_rich_demo_20251224_104855/
│       └── demo.html
├── json/
│   └── live_rich_demo_20251224_104855/
│       └── demo.json
└── thumbnails/
    └── svg/
        └── live_rich_demo_20251224_104855/
            ├── demo_first.svg
            ├── demo_middle.svg
            └── demo_last.svg
```

---

## Running the Examples

```powershell
# Comprehensive test (41 tests)
C:\RubyMSVC34\bin\ruby.exe examples\comprehensive_test.rb

# Rich-Ruby stress test (51 tests)
C:\RubyMSVC34\bin\ruby.exe examples\stress_test.rb

# asciinema-win stress test (26 tests)
C:\RubyMSVC34\bin\ruby.exe examples\asciinema_stress_test.rb

# Video export test (23 tests) - requires FFmpeg
C:\RubyMSVC34\bin\ruby.exe examples\video_export_test.rb

# Live Rich-Ruby demo
C:\RubyMSVC34\bin\ruby.exe examples\live_rich_demo.rb

# Rich-Ruby recording demo
C:\RubyMSVC34\bin\ruby.exe examples\rich_ruby_demo.rb
```
