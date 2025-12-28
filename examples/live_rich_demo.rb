# frozen_string_literal: true

# Live Rich-Ruby Recording Demo
#
# Demonstrates Rich-Ruby's interactive terminal rendering being recorded
# by asciinema-win, with organized output directories.
#
# Run with: C:\RubyMSVC34\bin\ruby.exe examples\live_rich_demo.rb

require_relative "../lib/asciinema_win"

puts "\e[1;36m╔══════════════════════════════════════════════════════════════╗\e[0m"
puts "\e[1;36m║         Live Rich-Ruby Recording Demo                        ║\e[0m"
puts "\e[1;36m╚══════════════════════════════════════════════════════════════╝\e[0m"
puts

# Create organized session
session = AsciinemaWin::OutputOrganizer.create_session("live_rich_demo")
puts "Session: #{session.id}"
puts

# Get terminal dimensions
width, height = Rich::Win32Console.get_size
rec_width = [width, 100].min
rec_height = [height, 40].min

# Pre-render all Rich-Ruby components
puts "Rendering Rich-Ruby components..."

# 1. Welcome Panel
puts "  → Rich::Panel..."
panel = Rich::Panel.new(
  "Welcome to Rich-Ruby!\n\nA pure Ruby library for beautiful terminal output\nwith native Windows Console API support.",
  title: "Rich-Ruby",
  border_style: "cyan",
  padding: 1
)
panel_output = panel.render(max_width: 60)

# 2. Data Table
puts "  → Rich::Table..."
table = Rich::Table.new(title: "System Information")
table.add_column("Metric", header_style: "bold cyan")
table.add_column("Value", justify: :right)
table.add_column("Status")
table.add_row("CPU Usage", "45%", "[green]●[/] Normal")
table.add_row("Memory", "8.2 GB / 16 GB", "[yellow]●[/] Moderate")
table.add_row("Disk I/O", "125 MB/s", "[green]●[/] Normal")
table.add_row("Network", "1.2 Gbps", "[green]●[/] Normal")
table.add_row("GPU", "RTX 4090", "[green]●[/] Idle")
table_output = table.render(max_width: 65)

# 3. Project Tree
puts "  → Rich::Tree..."
tree = Rich::Tree.new("[bold yellow]📁 asciinema-win/[/]")
lib = tree.add("[blue]📁 lib/[/]")
lib.add("[green]📄 asciinema_win.rb[/]")
aw = lib.add("[blue]📁 asciinema_win/[/]")
aw.add("[green]📄 recorder.rb[/]")
aw.add("[green]📄 player.rb[/]")
aw.add("[green]📄 export.rb[/]")
aw.add("[green]📄 themes.rb[/]")
aw.add("[green]📄 ansi_parser.rb[/]")
aw.add("[green]📄 output_organizer.rb[/]")
rich = lib.add("[blue]📁 rich/[/]")
rich.add("[green]📄 console.rb[/]")
rich.add("[green]📄 panel.rb[/]")
rich.add("[green]📄 table.rb[/]")
rich.add("[green]📄 tree.rb[/]")
rich.add("[green]📄 syntax.rb[/]")
examples = tree.add("[blue]📁 examples/[/]")
examples.add("[green]📄 rich_ruby_demo.rb[/]")
examples.add("[green]📄 comprehensive_test.rb[/]")
tree.add("[green]📄 README.md[/]")
tree.add("[yellow]📄 asciinema_win.gemspec[/]")
tree_output = tree.render

# 4. Code Syntax
puts "  → Rich::Syntax..."
code = <<~RUBY
  class TerminalRecorder
    def initialize(output_path)
      @path = output_path
      @session = AsciinemaWin::OutputOrganizer.create_session("demo")
    end

    def record
      AsciinemaWin::Asciicast.create(@session.recording_path) do |writer|
        yield writer if block_given?
      end
    end

    def export(format:, theme: "dracula")
      AsciinemaWin::Export.export(@path, @session.export_path(format), theme: theme)
    end
  end
RUBY
syntax = Rich::Syntax.new(code.strip, language: "ruby", theme: :dracula, line_numbers: true)
syntax_output = syntax.render

puts "  → All components rendered!"
puts

# Create recording
recording_path = session.recording_path("demo")
puts "Creating recording: #{recording_path}"

AsciinemaWin::Asciicast.create(
  recording_path,
  width: rec_width,
  height: rec_height,
  title: "Live Rich-Ruby Demo",
  env: { "SHELL" => "powershell.exe", "TERM" => "xterm-256color" }
) do |writer|
  time = 0.0

  # Clear screen
  writer.write_output(time, "\e[2J\e[H")
  time += 0.1

  # Header
  writer.write_output(time, "\e[1;36m╔═══════════════════════════════════════════════════════════════════╗\e[0m\r\n")
  time += 0.03
  writer.write_output(time, "\e[1;36m║               Rich-Ruby Live Terminal Demo                        ║\e[0m\r\n")
  time += 0.03
  writer.write_output(time, "\e[1;36m╚═══════════════════════════════════════════════════════════════════╝\e[0m\r\n\r\n")
  time += 0.5
  writer.write_marker(time, "header")

  # Demo 1: Panel
  writer.write_output(time, "\e[1;33m▶ 1. Rich::Panel - Bordered Container\e[0m\r\n\r\n")
  time += 0.3
  panel_output.each_line do |line|
    writer.write_output(time, line.chomp + "\r\n")
    time += 0.05
  end
  time += 0.7
  writer.write_marker(time, "panel")

  # Demo 2: Table
  writer.write_output(time, "\r\n\e[1;33m▶ 2. Rich::Table - Data Grid\e[0m\r\n\r\n")
  time += 0.3
  table_output.each_line do |line|
    writer.write_output(time, line.chomp + "\r\n")
    time += 0.04
  end
  time += 0.7
  writer.write_marker(time, "table")

  # Demo 3: Tree
  writer.write_output(time, "\r\n\e[1;33m▶ 3. Rich::Tree - Hierarchical View\e[0m\r\n\r\n")
  time += 0.3
  tree_output.each_line do |line|
    writer.write_output(time, line.chomp + "\r\n")
    time += 0.06
  end
  time += 0.7
  writer.write_marker(time, "tree")

  # Demo 4: Syntax
  writer.write_output(time, "\r\n\e[1;33m▶ 4. Rich::Syntax - Code Highlighting (Dracula Theme)\e[0m\r\n\r\n")
  time += 0.3
  syntax_output.each_line do |line|
    writer.write_output(time, line.chomp + "\r\n")
    time += 0.05
  end
  time += 0.7
  writer.write_marker(time, "syntax")

  # Demo 5: Animated Progress
  writer.write_output(time, "\r\n\e[1;33m▶ 5. Animated Progress Bar\e[0m\r\n\r\n")
  time += 0.3
  (0..25).each do |i|
    percent = (i * 4).clamp(0, 100)
    filled = (percent * 0.4).to_i
    empty = 40 - filled
    bar = "\e[32m#{"█" * filled}\e[0m#{"░" * empty}"
    writer.write_output(time, "\r  [#{bar}] #{format("%3d", percent)}%")
    time += 0.08
  end
  writer.write_output(time, " \e[32m✓ Complete!\e[0m\r\n")
  time += 0.5
  writer.write_marker(time, "progress")

  # Demo 6: Color Showcase
  writer.write_output(time, "\r\n\e[1;33m▶ 6. ANSI Color Palette\e[0m\r\n\r\n")
  time += 0.3

  # 16 colors
  writer.write_output(time, "  16 Standard Colors:\r\n  ")
  time += 0.1
  (30..37).each { |c| writer.write_output(time += 0.04, "\e[#{c}m▓▓\e[0m") }
  (90..97).each { |c| writer.write_output(time += 0.04, "\e[#{c}m▓▓\e[0m") }
  writer.write_output(time, "\r\n\r\n")

  # 256 color rainbow
  writer.write_output(time, "  256-Color Rainbow:\r\n  ")
  time += 0.1
  (16..51).each { |c| writer.write_output(time += 0.015, "\e[48;5;#{c}m \e[0m") }
  writer.write_output(time, "\r\n  ")
  (52..87).each { |c| writer.write_output(time += 0.015, "\e[48;5;#{c}m \e[0m") }
  writer.write_output(time, "\r\n  ")
  (88..123).each { |c| writer.write_output(time += 0.015, "\e[48;5;#{c}m \e[0m") }
  writer.write_output(time, "\r\n")
  time += 0.5
  writer.write_marker(time, "colors")

  # Footer
  writer.write_output(time, "\r\n\e[1;32m✓ Rich-Ruby demonstration complete!\e[0m\r\n")
  time += 0.2
  writer.write_output(time, "\e[90mAll output rendered using real Rich-Ruby components\e[0m\r\n")
  time += 0.1
  writer.write_output(time, "\e[90mRecorded by asciinema-win v#{AsciinemaWin::VERSION}\e[0m\r\n")
  writer.write_marker(time, "complete")
end

puts "✓ Recording complete"
puts

# Recording info
info = AsciinemaWin::Asciicast::Reader.info(recording_path)
puts "Recording info:"
puts "  Size: #{info[:width]}x#{info[:height]}"
puts "  Duration: #{format("%.2f", info[:duration])}s"
puts "  Events: #{info[:event_count]}"
puts

# Export to all formats
puts "Exporting..."

# All themes
AsciinemaWin::Themes.names.each do |theme|
  svg_path = session.export_path("demo_#{theme}", format: :svg)
  AsciinemaWin::Export.export(recording_path, svg_path, format: :svg, theme: theme)
  puts "  SVG (#{theme})"
end

# HTML
html_path = session.export_path("demo", format: :html)
AsciinemaWin::Export.export(recording_path, html_path, format: :html)
puts "  HTML"

# JSON
json_path = session.export_path("demo", format: :json)
AsciinemaWin::Export.export(recording_path, json_path, format: :json)
puts "  JSON"

# Thumbnails
puts "\nGenerating thumbnails..."
[:first, :middle, :last].each do |frame|
  thumb_path = session.thumbnail_path("demo", frame: frame)
  AsciinemaWin::Export.thumbnail(recording_path, thumb_path, frame: frame, theme: "dracula")
  puts "  #{frame}"
end

# Summary
puts "\n" + "=" * 60
puts session.summary
puts "=" * 60

puts "\n\e[32m✓ All exports complete!\e[0m"
puts "\nView the demo:"
puts "  start #{html_path.gsub("/", "\\")}"
