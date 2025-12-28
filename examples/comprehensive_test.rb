# frozen_string_literal: true

# Comprehensive Test Suite for asciinema-win
#
# Tests all core functionality with organized output.
# Run with: C:\RubyMSVC34\bin\ruby.exe examples\comprehensive_test.rb

require_relative "../lib/asciinema_win"

# Test framework (simple assertions)
class TestRunner
  attr_reader :passed, :failed, :tests

  def initialize
    @passed = 0
    @failed = 0
    @tests = []
  end

  def test(name)
    result = yield
    if result
      @passed += 1
      @tests << { name: name, status: :passed }
      puts "  \e[32m✓\e[0m #{name}"
    else
      @failed += 1
      @tests << { name: name, status: :failed }
      puts "  \e[31m✗\e[0m #{name}"
    end
  rescue StandardError => e
    @failed += 1
    @tests << { name: name, status: :failed, error: e.message }
    puts "  \e[31m✗\e[0m #{name}: #{e.message}"
  end

  def summary
    total = @passed + @failed
    puts "\n#{"=" * 60}"
    puts "Tests: #{total}, Passed: \e[32m#{@passed}\e[0m, Failed: \e[31m#{@failed}\e[0m"
    @failed.zero?
  end
end

# Create organized session
session = AsciinemaWin::OutputOrganizer.create_session("comprehensive_test")
puts "\e[1;36m╔══════════════════════════════════════════════════════════════╗\e[0m"
puts "\e[1;36m║         asciinema-win Comprehensive Test Suite                ║\e[0m"
puts "\e[1;36m╚══════════════════════════════════════════════════════════════╝\e[0m"
puts
puts "Session: #{session.id}"
puts

runner = TestRunner.new

# ==============================================================================
# Section 1: Module Loading
# ==============================================================================
puts "\e[1;33m▶ Module Loading\e[0m"

runner.test("AsciinemaWin module loads") { defined?(AsciinemaWin) }
runner.test("Asciicast module loads") { defined?(AsciinemaWin::Asciicast) }
runner.test("Recorder class loads") { defined?(AsciinemaWin::Recorder) }
runner.test("Player class loads") { defined?(AsciinemaWin::Player) }
runner.test("Export module loads") { defined?(AsciinemaWin::Export) }
runner.test("Themes module loads") { defined?(AsciinemaWin::Themes) }
runner.test("AnsiParser class loads") { defined?(AsciinemaWin::AnsiParser) }
runner.test("OutputOrganizer module loads") { defined?(AsciinemaWin::OutputOrganizer) }
runner.test("VERSION is defined") { defined?(AsciinemaWin::VERSION) && !AsciinemaWin::VERSION.empty? }

# ==============================================================================
# Section 2: Rich-Ruby Integration
# ==============================================================================
puts "\n\e[1;33m▶ Rich-Ruby Integration\e[0m"

runner.test("Rich module loads") { defined?(Rich) }
runner.test("Rich::Console loads") { defined?(Rich::Console) }
runner.test("Rich::Panel loads") { defined?(Rich::Panel) }
runner.test("Rich::Table loads") { defined?(Rich::Table) }
runner.test("Rich::Tree loads") { defined?(Rich::Tree) }
runner.test("Rich::Syntax loads") { defined?(Rich::Syntax) }
runner.test("Rich::Text loads") { defined?(Rich::Text) }

# Test actual Rich-Ruby rendering
runner.test("Rich::Panel renders content") do
  panel = Rich::Panel.new("Test content", title: "Test", border_style: "cyan")
  output = panel.render(max_width: 40)
  output.include?("Test content") && output.include?("Test")
end

runner.test("Rich::Table renders content") do
  table = Rich::Table.new(title: "Test Table")
  table.add_column("Col1")
  table.add_column("Col2")
  table.add_row("A", "B")
  output = table.render(max_width: 40)
  output.include?("Test Table") && output.include?("Col1")
end

runner.test("Rich::Tree renders content") do
  tree = Rich::Tree.new("Root")
  tree.add("Child 1")
  tree.add("Child 2")
  output = tree.render
  output.include?("Root") && output.include?("Child 1")
end

runner.test("Rich::Syntax renders Ruby code") do
  syntax = Rich::Syntax.new("puts 'hello'", language: "ruby", theme: :monokai, line_numbers: true)
  output = syntax.render
  output.include?("puts")
end

# ==============================================================================
# Section 3: Themes
# ==============================================================================
puts "\n\e[1;33m▶ Terminal Themes\e[0m"

runner.test("Themes.names returns array") { AsciinemaWin::Themes.names.is_a?(Array) }
runner.test("At least 5 themes available") { AsciinemaWin::Themes.names.length >= 5 }

%w[asciinema dracula monokai nord tokyo-night].each do |theme|
  runner.test("Theme '#{theme}' exists") do
    t = AsciinemaWin::Themes.get(theme)
    t && t.foreground && t.background
  end
end

# ==============================================================================
# Section 4: Recording with Real Rich-Ruby
# ==============================================================================
puts "\n\e[1;33m▶ Recording with Rich-Ruby\e[0m"

# Create a demo recording using real Rich-Ruby output
recording_path = session.recording_path("rich_demo")

# Pre-render Rich-Ruby components
panel_output = Rich::Panel.new("Welcome to Rich-Ruby!", title: "Panel", border_style: "green").render(max_width: 50)
table = Rich::Table.new(title: "Data")
table.add_column("Name")
table.add_column("Value", justify: :right)
table.add_row("CPU", "95%")
table.add_row("Memory", "2.1 GB")
table_output = table.render(max_width: 40)
tree = Rich::Tree.new("[yellow]Project[/]")
tree.add("[green]file1.rb[/]")
tree.add("[green]file2.rb[/]")
tree_output = tree.render

runner.test("Create recording with real Rich output") do
  AsciinemaWin::Asciicast.create(recording_path, width: 80, height: 24, title: "Rich-Ruby Demo") do |writer|
    time = 0.0
    writer.write_output(time, "\e[2J\e[H")
    time += 0.1

    # Write real Rich::Panel output
    writer.write_output(time, "\e[1;33m▶ Rich::Panel\e[0m\r\n")
    time += 0.2
    panel_output.each_line { |line| writer.write_output(time += 0.05, line.chomp + "\r\n") }
    time += 0.3

    # Write real Rich::Table output
    writer.write_output(time, "\r\n\e[1;33m▶ Rich::Table\e[0m\r\n")
    time += 0.2
    table_output.each_line { |line| writer.write_output(time += 0.05, line.chomp + "\r\n") }
    time += 0.3

    # Write real Rich::Tree output
    writer.write_output(time, "\r\n\e[1;33m▶ Rich::Tree\e[0m\r\n")
    time += 0.2
    tree_output.each_line { |line| writer.write_output(time += 0.05, line.chomp + "\r\n") }
    time += 0.3

    writer.write_output(time, "\r\n\e[32m✓ Complete!\e[0m\r\n")
    writer.write_marker(time, "complete")
  end
  File.exist?(recording_path)
end

runner.test("Recording file has content") { File.size(recording_path) > 100 }

runner.test("Recording has valid asciicast header") do
  info = AsciinemaWin::Asciicast::Reader.info(recording_path)
  info[:width] == 80 && info[:height] == 24
end

# ==============================================================================
# Section 5: Export Formats
# ==============================================================================
puts "\n\e[1;33m▶ Export Formats\e[0m"

runner.test("Export to SVG (asciinema theme)") do
  svg_path = session.export_path("demo_asciinema", format: :svg)
  AsciinemaWin::Export.export(recording_path, svg_path, format: :svg, theme: "asciinema")
  File.exist?(svg_path) && File.size(svg_path) > 500
end

runner.test("Export to SVG (dracula theme)") do
  svg_path = session.export_path("demo_dracula", format: :svg)
  AsciinemaWin::Export.export(recording_path, svg_path, format: :svg, theme: "dracula")
  File.exist?(svg_path) && File.read(svg_path).include?("#282a36")  # Dracula background
end

runner.test("Export to HTML") do
  html_path = session.export_path("demo", format: :html)
  AsciinemaWin::Export.export(recording_path, html_path, format: :html)
  File.exist?(html_path) && File.read(html_path).include?("asciinema-player")
end

runner.test("Export to JSON") do
  json_path = session.export_path("demo", format: :json)
  AsciinemaWin::Export.export(recording_path, json_path, format: :json)
  File.exist?(json_path) && File.read(json_path).include?('"events"')
end

runner.test("Export to Text") do
  txt_path = session.export_path("demo", format: :txt)
  AsciinemaWin::Export.export(recording_path, txt_path, format: :txt)
  File.exist?(txt_path)
end

# ==============================================================================
# Section 6: Advanced Features
# ==============================================================================
puts "\n\e[1;33m▶ Advanced Features\e[0m"

runner.test("Speed adjustment (2x)") do
  speed_path = session.export_path("speed_2x", format: :cast)
  AsciinemaWin::Export.adjust_speed(recording_path, speed_path, speed: 2.0)
  orig = AsciinemaWin::Asciicast::Reader.info(recording_path)
  adj = AsciinemaWin::Asciicast::Reader.info(speed_path)
  adj[:duration] < orig[:duration]
end

runner.test("Thumbnail generation (last frame)") do
  thumb_path = session.thumbnail_path("demo", frame: :last)
  AsciinemaWin::Export.thumbnail(recording_path, thumb_path, frame: :last, theme: "dracula")
  File.exist?(thumb_path) && File.size(thumb_path) > 100
end

runner.test("Recording concatenation") do
  # Create second recording
  second_path = session.export_path("second", format: :cast)
  AsciinemaWin::Asciicast.create(second_path, width: 80, height: 24, title: "Second") do |writer|
    writer.write_output(0.0, "Second recording\r\n")
    writer.write_output(0.5, "Done!\r\n")
  end

  combined_path = session.export_path("combined", format: :cast)
  AsciinemaWin::Export.concatenate([recording_path, second_path], combined_path, gap: 0.5)

  combined_info = AsciinemaWin::Asciicast::Reader.info(combined_path)
  combined_info[:event_count] > 10
end

# ==============================================================================
# Section 7: ANSI Parser
# ==============================================================================
puts "\n\e[1;33m▶ ANSI Parser\e[0m"

runner.test("AnsiParser parses colors") do
  parser = AsciinemaWin::AnsiParser.new(width: 40, height: 5)
  lines = parser.parse("\e[31mRed\e[0m \e[32mGreen\e[0m")
  lines[0].chars[0].fg == 31  # Red
end

runner.test("AnsiParser handles cursor movement") do
  parser = AsciinemaWin::AnsiParser.new(width: 10, height: 5)
  lines = parser.parse("ABCD\e[2GXYZ")
  lines[0].chars[1].char == "X"  # Cursor moved to column 2
end

runner.test("AnsiParser handles 256 colors") do
  parser = AsciinemaWin::AnsiParser.new(width: 20, height: 2)
  lines = parser.parse("\e[38;5;196mBright Red\e[0m")
  lines[0].chars[0].fg == 196
end

# ==============================================================================
# Summary
# ==============================================================================
success = runner.summary

puts "\nSession outputs: #{session.id}"
puts "  Recordings: asciinema_output/recordings/#{session.id}/"
puts "  SVGs: asciinema_output/svg/#{session.id}/"
puts "  HTML: asciinema_output/html/#{session.id}/"
puts "  Thumbnails: asciinema_output/thumbnails/svg/#{session.id}/"

exit(success ? 0 : 1)
