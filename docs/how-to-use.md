# How-To Use asciinema-win + Rich-Ruby

This guide provides quick examples for using the library effectively.

---

## 1. Quick Start: Recording & Playback

### Record a Terminal Session
```powershell
C:\RubyMSVC34\bin\ruby.exe -Ilib exe\asciinema_win rec session.cast
# Exit with Ctrl+D
```

### Record a Specific Command
```powershell
C:\RubyMSVC34\bin\ruby.exe -Ilib exe\asciinema_win rec -c "dir /s" output.cast
```

### Play Back a Recording
```powershell
C:\RubyMSVC34\bin\ruby.exe -Ilib exe\asciinema_win play session.cast
```

### Play at 2x Speed
```powershell
C:\RubyMSVC34\bin\ruby.exe -Ilib exe\asciinema_win play -s 2 session.cast
```

---

## 2. Exporting Recordings

### Export to HTML (interactive player)
```powershell
C:\RubyMSVC34\bin\ruby.exe -Ilib exe\asciinema_win export session.cast -o output.html
```

### Export to SVG (themed snapshot)
```powershell
C:\RubyMSVC34\bin\ruby.exe -Ilib exe\asciinema_win export session.cast -f svg -o output.svg
```

### Using Ruby API for Export
```ruby
require 'asciinema_win'

# Export with theme
AsciinemaWin::Export.export("demo.cast", "demo.svg", format: :svg, theme: "dracula")

# Generate thumbnail
AsciinemaWin::Export.thumbnail("demo.cast", "thumb.svg", frame: :last, theme: "monokai")

# Speed up recording
AsciinemaWin::Export.adjust_speed("input.cast", "fast.cast", speed: 2.0, max_idle: 0.5)

# Combine recordings
AsciinemaWin::Export.concatenate(["part1.cast", "part2.cast"], "combined.cast")
```

---

## 3. Rich-Ruby Terminal Formatting

### Basic Styled Output
```ruby
require 'rich'

Rich.print("[bold red]ERROR:[/] Something went wrong!")
Rich.print("[green]SUCCESS:[/] Operation completed.")
Rich.print("[cyan italic]INFO:[/] Processing data...")
```

### Panels (Bordered Boxes)
```ruby
panel = Rich::Panel.new(
  "Important message here.",
  title: "Notice",
  border_style: "cyan"
)
puts panel.render(max_width: 50)
```

### Tables
```ruby
table = Rich::Table.new(title: "Inventory")
table.add_column("Item", header_style: "bold")
table.add_column("Stock", justify: :right)
table.add_row("Apples", "50")
table.add_row("Oranges", "12")
puts table.render(max_width: 40)
```

### Trees
```ruby
tree = Rich::Tree.new("[yellow]Project[/]")
tree.add("[green]src/[/]")
tree.add("[green]lib/[/]")
tree.add("[blue]README.md[/]")
puts tree.render
```

### Syntax Highlighting
```ruby
code = "def hello; puts 'world'; end"
syntax = Rich::Syntax.new(code, language: "ruby", theme: :monokai, line_numbers: true)
puts syntax.render
```

---

## 4. Organized Output

Use sessions for organized output directories:

```ruby
session = AsciinemaWin::OutputOrganizer.create_session("my_demo")

# All outputs are organized by timestamp and format
recording = session.recording_path("demo")
svg = session.export_path("demo", format: :svg)
thumb = session.thumbnail_path("demo", frame: :last)

# View session summary
puts session.summary
```

Output structure:
```
asciinema_output/
├── recordings/my_demo_20251224_120000/
├── svg/my_demo_20251224_120000/
├── html/my_demo_20251224_120000/
├── thumbnails/svg/my_demo_20251224_120000/
└── ...
```

---

## 5. Quick Reference

| Task | Tool |
|------|------|
| Record session | `asciinema_win rec file.cast` |
| Record command | `asciinema_win rec -c "cmd" file.cast` |
| Playback | `asciinema_win play file.cast` |
| Export to HTML | `asciinema_win export file.cast -o output.html` |
| Export to SVG | `AsciinemaWin::Export.export(...)` |
| Styled text | `Rich.print("[bold red]text[/]")` |
| Bordered box | `Rich::Panel.new(...)` |
| Data table | `Rich::Table.new(...)` |
| Tree view | `Rich::Tree.new(...)` |
| Code highlight | `Rich::Syntax.new(...)` |
