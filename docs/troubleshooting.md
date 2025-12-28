# Troubleshooting

Common issues and solutions for asciinema-win + Rich-Ruby.

---

## Recording Issues

### "Console size detection failed"
**Cause:** Running in a non-console environment (e.g., IDE terminal).
**Solution:** Use Windows Terminal or PowerShell directly.

### Recording file is empty or very small
**Cause:** Recording stopped too quickly.
**Solution:** Ensure you press Ctrl+D to stop recording properly.

### Colors not appearing in recording
**Cause:** Terminal doesn't support ANSI/VT processing.
**Solution:** Use Windows Terminal or enable VT mode in PowerShell:
```powershell
# PowerShell 5.1+
$host.UI.RawUI.WindowTitle = "VT Mode"
```

---

## Playback Issues

### "File not found" error
**Cause:** Incorrect path or missing file.
**Solution:** Use full path to the .cast file.

### Playback too fast or slow
**Solution:** Use speed option:
```powershell
asciinema_win play -s 0.5 file.cast  # Half speed
asciinema_win play -s 2 file.cast    # Double speed
```

---

## Export Issues

### SVG colors look wrong
**Cause:** Theme not matching source colors.
**Solution:** Try different theme:
```ruby
AsciinemaWin::Export.export("file.cast", "out.svg", format: :svg, theme: "dracula")
```

### HTML player not loading
**Cause:** CDN blocked or offline.
**Solution:** HTML embeds asciinema-player from CDN. Check internet connection.

---

## Rich-Ruby Issues

### Unicode characters display incorrectly
**Cause:** Console font doesn't support Unicode.
**Solution:** Use a font like Cascadia Code or Consolas.

### Colors don't display
**Cause:** Terminal doesn't support colors or ANSI is disabled.
**Solution:** Use Windows Terminal or enable VT processing.

### Table columns misaligned
**Cause:** Wide Unicode characters (CJK, emoji).
**Solution:** This is handled automatically, but ensure max_width is sufficient.

---

## Environment Issues

### "ruby: command not found"
**Solution:** Use full path:
```powershell
C:\RubyMSVC34\bin\ruby.exe -Ilib exe\asciinema_win rec test.cast
```

### Gem install fails
**Solution:** Build gem first:
```powershell
C:\RubyMSVC34\bin\gem.bat build asciinema_win.gemspec
C:\RubyMSVC34\bin\gem.bat install asciinema_win-0.1.0.gem
```

---

## Getting Help

1. Check documentation: `docs/` folder
2. Run tests: `ruby examples/comprehensive_test.rb`
3. Check context: `context.md` for full project details
