# Customization

How to customize asciinema-win + Rich-Ruby for your needs.

---

## Custom Themes

Create your own terminal theme for SVG exports:

```ruby
# Define custom theme
custom_theme = AsciinemaWin::Themes::Theme.new(
  foreground: "#e0e0e0",
  background: "#1e1e2e",
  palette: [
    "#45475a",  # Black (0)
    "#f38ba8",  # Red (1)
    "#a6e3a1",  # Green (2)
    "#f9e2af",  # Yellow (3)
    "#89b4fa",  # Blue (4)
    "#f5c2e7",  # Magenta (5)
    "#94e2d5",  # Cyan (6)
    "#bac2de",  # White (7)
    "#585b70",  # Bright Black (8)
    "#f38ba8",  # Bright Red (9)
    "#a6e3a1",  # Bright Green (10)
    "#f9e2af",  # Bright Yellow (11)
    "#89b4fa",  # Bright Blue (12)
    "#f5c2e7",  # Bright Magenta (13)
    "#94e2d5",  # Bright Cyan (14)
    "#a6adc8"   # Bright White (15)
  ]
)

# Use custom theme
AsciinemaWin::Themes.register("catppuccin", custom_theme)
AsciinemaWin::Export.export("demo.cast", "out.svg", format: :svg, theme: "catppuccin")
```

---

## Custom Rich Styles

Create reusable styles:

```ruby
# Define custom styles
styles = {
  error: "bold red",
  warning: "yellow",
  success: "bold green",
  info: "cyan",
  muted: "dim"
}

# Use with Rich
Rich.print("[#{styles[:error]}]ERROR:[/] Something failed")
Rich.print("[#{styles[:success]}]SUCCESS:[/] All done")
```

---

## Custom Box Styles

Use different box characters for panels:

```ruby
# Built-in box styles
Rich::Box::ASCII      # +--+
Rich::Box::SQUARE     # ┌─┐
Rich::Box::ROUNDED    # ╭─╮
Rich::Box::HEAVY      # ┏━┓
Rich::Box::DOUBLE     # ╔═╗
Rich::Box::MINIMAL    # No corners

# Use in Panel
panel = Rich::Panel.new("Content", box: Rich::Box::DOUBLE)
```

---

## Custom Output Organization

Override output directory structure:

```ruby
# Custom base directory
session = AsciinemaWin::OutputOrganizer.create_session(
  "my_session",
  base_dir: "my_output"
)

# Or use direct paths
AsciinemaWin::OutputOrganizer.output_path(
  "demo",
  format: :svg,
  base_dir: "custom_folder",
  timestamp: false  # No timestamp in filename
)
```

---

## Custom Syntax Themes

Rich::Syntax supports multiple highlighting themes:

```ruby
# Available themes
themes = [:monokai, :dracula, :github, :solarized]

themes.each do |theme|
  syntax = Rich::Syntax.new(code, language: "ruby", theme: theme)
  puts "== #{theme} =="
  puts syntax.render
end
```

---

## Recording Options

Customize recording behavior:

```ruby
# Create recorder with options
recorder = AsciinemaWin::Recorder.new(
  output_path: "session.cast",
  title: "My Demo",
  idle_time_limit: 2.0,  # Limit idle time
  capture_interval: 0.033  # ~30 fps
)

# Programmatic control
recorder.start
# ... your code ...
recorder.add_marker("checkpoint")
# ... more code ...
recorder.stop
```
