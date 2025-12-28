# Architecture & Data Flow

This document explains the architecture of asciinema-win + Rich-Ruby.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        asciinema-win                             │
├─────────────────────────────────────────────────────────────────┤
│  CLI Layer                    │  Ruby API                        │
│  ├── rec                      │  ├── AsciinemaWin.record()       │
│  ├── play                     │  ├── AsciinemaWin.play()         │
│  ├── export                   │  ├── AsciinemaWin::Export        │
│  ├── cat                      │  └── AsciinemaWin::Asciicast     │
│  └── info                     │                                   │
├─────────────────────────────────────────────────────────────────┤
│                         Core Engine                               │
│  ├── Recorder    - Background capture with timing                │
│  ├── Player      - Playback with speed control                   │
│  ├── Asciicast   - File format (Header, Event, Writer, Reader)   │
│  ├── Export      - SVG, HTML, JSON, text, thumbnails             │
│  ├── Themes      - 9 terminal color palettes                     │
│  └── AnsiParser  - ANSI escape sequence parsing                  │
├─────────────────────────────────────────────────────────────────┤
│                         Rich-Ruby                                 │
│  ├── Console     - Terminal interface                            │
│  ├── Panel       - Bordered containers                           │
│  ├── Table       - Data grids                                    │
│  ├── Tree        - Hierarchical views                            │
│  ├── Syntax      - Code highlighting                             │
│  ├── Color       - 16/256/TrueColor                              │
│  └── Style       - Bold, italic, underline, etc.                 │
├─────────────────────────────────────────────────────────────────┤
│                       Win32 Console API                           │
│  (via Ruby's Fiddle - zero external dependencies)                │
│  ├── GetConsoleScreenBufferInfo                                  │
│  ├── ReadConsoleOutputW                                          │
│  ├── SetConsoleMode (enable VT processing)                       │
│  └── WriteConsoleW                                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Recording Pipeline

1. **Initialization**: Create output file with asciicast v2 header
2. **Capture Thread**: Background thread captures screen buffer at 30fps
3. **Delta Detection**: Compare current buffer with previous, emit only changes
4. **ANSI Generation**: Convert Windows attributes to ANSI escape sequences
5. **Event Writing**: Write timestamped events to .cast file
6. **Finalization**: Close file on Ctrl+D or process exit

---

## Playback Pipeline

1. **Load**: Read and parse asciicast v2 file
2. **Validate**: Check header and event format
3. **Timing**: Sleep between events (adjusted by speed factor)
4. **Render**: Write event data to terminal
5. **Markers**: Optionally pause at marker events

---

## Export Pipeline

1. **Parse**: Load recording and collect all output events
2. **ANSI Parse**: Parse escape sequences → styled characters
3. **Theme Apply**: Map ANSI colors to theme palette
4. **Render**: Generate output format (SVG, HTML, JSON, text)

---

## Rich-Ruby Rendering Pipeline

1. **Input**: Markup string or component (Panel, Table, etc.)
2. **Parse**: Convert markup to Text with Spans
3. **Segment**: Break into Segment objects (text + style)
4. **Measure**: Calculate cell widths (Unicode-aware)
5. **Layout**: Apply wrapping, alignment, borders
6. **ANSI**: Generate escape sequences
7. **Output**: Write to terminal

---

## Windows Console Integration

Rich-Ruby and asciinema-win use `Fiddle` to call Windows Console APIs:

```ruby
# Enable ANSI/VT processing
SetConsoleMode(handle, ENABLE_VIRTUAL_TERMINAL_PROCESSING)

# Get terminal dimensions
GetConsoleScreenBufferInfo(handle, info_ptr)

# Read screen buffer for recording
ReadConsoleOutputW(handle, buffer, size, coord, region)
```

This is a pure Ruby approach - no C extensions, no external dependencies.
