# frozen_string_literal: true

# Rich-Ruby Recording Demo
#
# This script demonstrates real Rich-Ruby terminal rendering being recorded
# by asciinema-win. Uses actual Rich components, not simulated output.
#
# Run with: C:\RubyMSVC34\bin\ruby.exe examples\rich_ruby_demo.rb

require_relative "../lib/asciinema_win"

puts "\e[1;36m╔══════════════════════════════════════════════════════╗\e[0m"
puts "\e[1;36m║    Rich-Ruby + asciinema-win Recording Demo          ║\e[0m"
puts "\e[1;36m╚══════════════════════════════════════════════════════╝\e[0m"
puts

# Create organized session
session = AsciinemaWin::OutputOrganizer.create_session("rich_ruby_demo")
puts "Session: #{session.id}"
puts "Output directory: #{session.directory}"
puts

# Get terminal dimensions
width, height = Rich::Win32Console.get_size
rec_width = [width, 100].min
rec_height = [height, 40].min

# Prepare all Rich-Ruby rendered content BEFORE recording
puts "Preparing Rich-Ruby components..."

# 1. Render Panel
welcome_panel = Rich::Panel.new(
  "Welcome to Rich-Ruby!\n\nA pure Ruby library for beautiful terminal output.",
  title: "Rich-Ruby",
  border_style: "cyan",
  padding: 1
).render(max_width: 60)

# 2. Render Table
languages_table = Rich::Table.new(title: "Programming Languages")
languages_table.add_column("Language", header_style: "bold cyan")
languages_table.add_column("Year", justify: :center)
languages_table.add_column("Creator")
languages_table.add_row("Ruby", "1995", "Yukihiro Matsumoto")
languages_table.add_row("Python", "1991", "Guido van Rossum")
languages_table.add_row("JavaScript", "1995", "Brendan Eich")
languages_table.add_row("Rust", "2010", "Graydon Hoare")
languages_table.add_row("Go", "2009", "Rob Pike")
languages_table_output = languages_table.render(max_width: 70)

# 3. Render Tree
project_tree = Rich::Tree.new("[bold yellow]asciinema-win/[/]")
lib = project_tree.add("[blue]lib/[/]")
lib.add("[green]asciinema_win.rb[/]")
asciinema_subdir = lib.add("[blue]asciinema_win/[/]")
asciinema_subdir.add("[green]recorder.rb[/]")
asciinema_subdir.add("[green]player.rb[/]")
asciinema_subdir.add("[green]export.rb[/]")
asciinema_subdir.add("[green]themes.rb[/]")
rich_subdir = lib.add("[blue]rich/[/]")
rich_subdir.add("[green]console.rb[/]")
rich_subdir.add("[green]panel.rb[/]")
rich_subdir.add("[green]table.rb[/]")
rich_subdir.add("[green]tree.rb[/]")
rich_subdir.add("[green]syntax.rb[/]")
examples = project_tree.add("[blue]examples/[/]")
examples.add("[green]rich_ruby_demo.rb[/]")
project_tree.add("[green]README.md[/]")
project_tree_output = project_tree.render

# 4. Render Syntax Highlighting
ruby_code = <<~RUBY
  class Greeter
    def initialize(name)
      @name = name
    end

    def greet
      puts "Hello, \#{@name}!"
    end
  end

  Greeter.new("World").greet
RUBY

syntax = Rich::Syntax.new(ruby_code.strip, language: "ruby", theme: :monokai, line_numbers: true)
syntax_output = syntax.render

puts "  ✓ Panel rendered"
puts "  ✓ Table rendered"
puts "  ✓ Tree rendered"
puts "  ✓ Syntax highlighting rendered"
puts

# Now create the recording with real Rich-Ruby output
recording_path = session.recording_path("demo")
puts "Creating recording: #{File.basename(recording_path)}"

AsciinemaWin::Asciicast.create(
  recording_path,
  width: rec_width,
  height: rec_height,
  title: "Rich-Ruby Terminal Demo",
  env: { "SHELL" => "powershell.exe", "TERM" => "xterm-256color" }
) do |writer|
  time = 0.0

  # Clear screen
  writer.write_output(time, "\e[2J\e[H")
  time += 0.1

  # Header
  writer.write_output(time, "\e[1;36m╔══════════════════════════════════════════════════════════════════╗\e[0m\r\n")
  time += 0.05
  writer.write_output(time, "\e[1;36m║              Rich-Ruby Terminal Rendering Demo                    ║\e[0m\r\n")
  time += 0.05
  writer.write_output(time, "\e[1;36m╚══════════════════════════════════════════════════════════════════╝\e[0m\r\n\r\n")
  time += 0.5
  writer.write_marker(time, "header")

  # ============================================================================
  # Demo 1: Panel (Real Rich::Panel output)
  # ============================================================================
  writer.write_output(time, "\e[1;33m▶ 1. Rich::Panel\e[0m\r\n\r\n")
  time += 0.3

  welcome_panel.each_line do |line|
    writer.write_output(time, line.chomp + "\r\n")
    time += 0.06
  end
  time += 0.5
  writer.write_marker(time, "panel_complete")

  # ============================================================================
  # Demo 2: Table (Real Rich::Table output)
  # ============================================================================
  writer.write_output(time, "\r\n\e[1;33m▶ 2. Rich::Table\e[0m\r\n\r\n")
  time += 0.3

  languages_table_output.each_line do |line|
    writer.write_output(time, line.chomp + "\r\n")
    time += 0.05
  end
  time += 0.5
  writer.write_marker(time, "table_complete")

  # ============================================================================
  # Demo 3: Tree (Real Rich::Tree output)
  # ============================================================================
  writer.write_output(time, "\r\n\e[1;33m▶ 3. Rich::Tree\e[0m\r\n\r\n")
  time += 0.3

  project_tree_output.each_line do |line|
    writer.write_output(time, line.chomp + "\r\n")
    time += 0.08
  end
  time += 0.5
  writer.write_marker(time, "tree_complete")

  # ============================================================================
  # Demo 4: Syntax Highlighting (Real Rich::Syntax output)
  # ============================================================================
  writer.write_output(time, "\r\n\e[1;33m▶ 4. Rich::Syntax (Ruby code with Monokai theme)\e[0m\r\n\r\n")
  time += 0.3

  syntax_output.each_line do |line|
    writer.write_output(time, line.chomp + "\r\n")
    time += 0.06
  end
  time += 0.5
  writer.write_marker(time, "syntax_complete")

  # ============================================================================
  # Demo 5: Progress Bar Animation
  # ============================================================================
  writer.write_output(time, "\r\n\e[1;33m▶ 5. Animated Progress Bar\e[0m\r\n\r\n")
  time += 0.3

  (0..20).each do |i|
    percent = i * 5
    filled = i * 2
    empty = 40 - filled
    bar = "\e[32m#{"█" * filled}\e[0m#{"░" * empty}"
    writer.write_output(time, "\r  [#{bar}] #{format("%3d", percent)}%")
    time += 0.1
  end
  writer.write_output(time, " \e[32m✓ Complete!\e[0m\r\n")
  time += 0.5
  writer.write_marker(time, "progress_complete")

  # ============================================================================
  # Demo 6: Color Palette
  # ============================================================================
  writer.write_output(time, "\r\n\e[1;33m▶ 6. ANSI Color Palette\e[0m\r\n\r\n")
  time += 0.3

  # Standard colors
  writer.write_output(time, "  Standard 16 colors:\r\n  ")
  time += 0.1
  (30..37).each do |c|
    writer.write_output(time, "\e[#{c}m██\e[0m")
    time += 0.05
  end
  (90..97).each do |c|
    writer.write_output(time, "\e[#{c}m██\e[0m")
    time += 0.05
  end
  writer.write_output(time, "\r\n\r\n")
  time += 0.2

  # 256 color gradient
  writer.write_output(time, "  256-color gradient:\r\n  ")
  time += 0.1
  (16..51).each do |c|
    writer.write_output(time, "\e[48;5;#{c}m \e[0m")
    time += 0.02
  end
  writer.write_output(time, "\r\n  ")
  time += 0.05
  (52..87).each do |c|
    writer.write_output(time, "\e[48;5;#{c}m \e[0m")
    time += 0.02
  end
  writer.write_output(time, "\r\n")
  time += 0.5
  writer.write_marker(time, "colors_complete")

  # Footer
  writer.write_output(time, "\r\n\e[1;32m✓ Rich-Ruby demonstration complete!\e[0m\r\n")
  time += 0.2
  writer.write_output(time, "\e[90mRecording generated by asciinema-win v#{AsciinemaWin::VERSION}\e[0m\r\n")
  time += 0.1
  writer.write_output(time, "\e[90mAll components rendered using real Rich-Ruby library\e[0m\r\n")

  writer.write_marker(time, "demo_complete")
end

puts "✓ Recording complete"
puts

# Get recording info
info = AsciinemaWin::Asciicast::Reader.info(recording_path)
puts "Recording info:"
puts "  Size: #{info[:width]}x#{info[:height]}"
puts "  Duration: #{format("%.2f", info[:duration])}s"
puts "  Events: #{info[:event_count]}"
puts

# Export to all formats with organized paths
puts "Exporting to organized directories..."

# Export to multiple themes
themes_to_export = %w[asciinema dracula monokai tokyo-night nord]
themes_to_export.each do |theme|
  svg_path = session.export_path("demo_#{theme}", format: :svg)
  AsciinemaWin::Export.export(recording_path, svg_path, format: :svg, theme: theme)
  puts "  SVG (#{theme}): #{File.basename(svg_path)}"
end

# Export HTML
html_path = session.export_path("demo", format: :html)
AsciinemaWin::Export.export(recording_path, html_path, format: :html)
puts "  HTML: #{File.basename(html_path)}"

# Export JSON
json_path = session.export_path("demo", format: :json)
AsciinemaWin::Export.export(recording_path, json_path, format: :json)
puts "  JSON: #{File.basename(json_path)}"

# Export Text
txt_path = session.export_path("demo", format: :txt)
AsciinemaWin::Export.export(recording_path, txt_path, format: :txt)
puts "  Text: #{File.basename(txt_path)}"

# Generate thumbnails for different frames
puts "\nGenerating thumbnails..."
[:first, :middle, :last].each do |frame|
  thumb_path = session.thumbnail_path("demo", frame: frame)
  AsciinemaWin::Export.thumbnail(recording_path, thumb_path, frame: frame, theme: "dracula")
  puts "  Thumbnail (#{frame}): #{File.basename(thumb_path)}"
end

# Print session summary
puts "\n" + "=" * 60
puts session.summary
puts "=" * 60

puts "\n\e[32m✓ All exports complete!\e[0m"
puts "\nView the demo:"
puts "  start #{html_path.gsub("/", "\\")}"
