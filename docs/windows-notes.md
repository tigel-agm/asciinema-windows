# Windows-Specific Notes

Notes for running asciinema-win + Rich-Ruby on Windows.

---

## Supported Windows Versions

| Version | Status |
|---------|--------|
| Windows 11 | Full support |
| Windows 10 (1903+) | Full support |
| Windows 10 (older) | May require VT mode setup |
| Windows 8.1 | Not supported |
| Windows 7 | Not supported |

---

## Terminal Support

| Terminal | ANSI Colors | Recording | Notes |
|----------|-------------|-----------|-------|
| Windows Terminal | Full | Full | Recommended |
| PowerShell 7+ | Full | Full | Good support |
| PowerShell 5.1 | Full | Full | Enable VT mode |
| cmd.exe | Limited | Full | Limited colors |
| VS Code Terminal | Limited | Limited | May need settings |

---

## Enabling VT (Virtual Terminal) Processing

The library automatically enables VT processing. If you experience issues:

```powershell
# PowerShell - Set console mode manually
$mode = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

Or use Windows Terminal which has VT enabled by default.

---

## Console API Used

asciinema-win uses these Win32 Console APIs via Ruby's Fiddle:

| API | Purpose |
|-----|---------|
| `GetStdHandle` | Get console handle |
| `GetConsoleMode` | Get current mode |
| `SetConsoleMode` | Enable VT processing |
| `GetConsoleScreenBufferInfo` | Get size and cursor |
| `ReadConsoleOutputW` | Capture screen buffer |
| `WriteConsoleW` | Write output |

---

## Ruby Environment

Recommended setup:
```
Ruby: 3.4.8 (MSVC build)
Path: C:\RubyMSVC34
Build: From source with Visual Studio 2026
Dependencies: vcpkg (OpenSSL, Zlib, LibYAML, LibFFI)
```

---

## File Paths

Windows uses backslashes, but Ruby accepts both:
```ruby
# Both work
path = "C:\\Users\\demo.cast"
path = "C:/Users/demo.cast"
```

---

## Known Limitations

1. **PTY not available**: Windows doesn't have Unix PTY. asciinema-win uses screen buffer capture instead.
2. **ConPTY not used**: We use direct screen buffer capture for broader compatibility.
3. **Video export**: Requires external codecs (x264, x265).
