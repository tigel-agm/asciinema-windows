# Test Report

Last updated: December 24, 2025

---

## Summary

| Suite | Tests | Passed | Failed | Duration |
|-------|-------|--------|--------|----------|
| Comprehensive | 41 | 41 | 0 | ~1.2s |
| Stress | 51 | 51 | 0 | ~0.9s |
| **Total** | **92** | **92** | **0** | ~2.1s |

---

## Comprehensive Test Output

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

## Stress Test Output

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

## Running Tests

```powershell
# Comprehensive test (41 tests)
C:\RubyMSVC34\bin\ruby.exe examples\comprehensive_test.rb

# Stress test (51 tests)
C:\RubyMSVC34\bin\ruby.exe examples\stress_test.rb

# Both
C:\RubyMSVC34\bin\ruby.exe examples\comprehensive_test.rb ; C:\RubyMSVC34\bin\ruby.exe examples\stress_test.rb
```
