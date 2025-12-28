# Cheat Sheet

Quick reference for asciinema-win + Rich-Ruby.

---

## CLI Commands

| Command | Description |
|---------|-------------|
| `asciinema_win rec file.cast` | Record terminal session |
| `asciinema_win rec -c "cmd" file.cast` | Record specific command |
| `asciinema_win play file.cast` | Play back recording |
| `asciinema_win play -s 2 file.cast` | Play at 2x speed |
| `asciinema_win export file.cast -o out.html` | Export to HTML |
| `asciinema_win export file.cast -f svg -o out.svg` | Export to SVG |
| `asciinema_win export file.cast -o out.gif` | Export to GIF (requires FFmpeg) |
| `asciinema_win export file.cast -o out.mp4 --fps 30` | Export to MP4 |
| `asciinema_win export file.cast -o out.gif --theme dracula` | Export with theme |
| `asciinema_win cat file.cast` | Output to stdout |
| `asciinema_win info file.cast` | Show recording info |

---

## Ruby API

```ruby
require 'asciinema_win'

# Recording
AsciinemaWin.record("file.cast", title: "Demo")
AsciinemaWin.record("file.cast", command: "dir")

# Playback
AsciinemaWin.play("file.cast", speed: 2.0)

# Export
AsciinemaWin::Export.export("in.cast", "out.svg", format: :svg, theme: "dracula")
AsciinemaWin::Export.export("in.cast", "out.gif", format: :gif, fps: 10)  # Video export
AsciinemaWin::Export.export("in.cast", "out.mp4", format: :mp4, fps: 30)
AsciinemaWin::Export.thumbnail("in.cast", "thumb.svg", frame: :last)
AsciinemaWin::Export.adjust_speed("in.cast", "out.cast", speed: 2.0, max_idle: 0.5)
AsciinemaWin::Export.concatenate(["a.cast", "b.cast"], "combined.cast")
```

---

## Rich-Ruby

```ruby
require 'rich'

# Styled output
Rich.print("[bold red]Error[/] Message")
Rich.print("[green]Success[/] Done")

# Components
Rich::Panel.new("content", title: "Title").render(max_width: 50)
Rich::Table.new(title: "Data")
Rich::Tree.new("Root")
Rich::Syntax.new(code, language: "ruby", theme: :monokai)
```

---

## Markup Syntax

| Syntax | Effect |
|--------|--------|
| `[bold]text[/]` | **Bold** |
| `[italic]text[/]` | *Italic* |
| `[red]text[/]` | Red text |
| `[on blue]text[/]` | Blue background |
| `[bold red on white]` | Combined |

---

## Available Themes

`asciinema`, `dracula`, `monokai`, `solarized-dark`, `solarized-light`, `nord`, `one-dark`, `github-dark`, `tokyo-night`
