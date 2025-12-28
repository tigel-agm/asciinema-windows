# frozen_string_literal: true

# Stress tests for asciinema-win
# Tests recording, export, and advanced features under heavy load
#
# Run with: C:\RubyMSVC34\bin\ruby.exe examples\asciinema_stress_test.rb

require_relative "../lib/asciinema_win"

class AsciinemaStressTest
  attr_reader :name, :passed, :error, :duration

  def initialize(name, &block)
    @name = name
    @block = block
    @passed = false
    @error = nil
    @duration = 0
  end

  def run
    start = Time.now
    begin
      @block.call
      @passed = true
    rescue StandardError => e
      @error = e
      @passed = false
    end
    @duration = Time.now - start
    self
  end
end

class AsciinemaStressTestSuite
  def initialize
    @tests = []
    @session = AsciinemaWin::OutputOrganizer.create_session("stress_test")
  end

  attr_reader :session

  def test(name, &block)
    @tests << AsciinemaStressTest.new(name, &block)
  end

  def run_all
    puts "=" * 70
    puts "asciinema-win Stress Test Suite"
    puts "=" * 70
    puts ""

    @tests.each do |t|
      print "  #{t.name.ljust(50)}... "
      t.run
      if t.passed
        puts "PASS (#{format("%.3f", t.duration)}s)"
      else
        puts "FAIL"
        puts "    Error: #{t.error.message}"
        puts "    #{t.error.backtrace.first}"
      end
    end

    passed = @tests.count(&:passed)
    total = @tests.length
    total_time = @tests.sum(&:duration)

    puts ""
    puts "=" * 70
    puts "Results: #{passed}/#{total} tests passed in #{format("%.2f", total_time)}s"
    puts "=" * 70

    passed == total
  end
end

suite = AsciinemaStressTestSuite.new

# =============================================================================
# ASCIICAST FORMAT STRESS TESTS
# =============================================================================

suite.test("Create recording with 10,000 events") do
  path = suite.session.recording_path("large_recording")
  AsciinemaWin::Asciicast.create(path, width: 80, height: 24, title: "Large Recording") do |writer|
    10_000.times do |i|
      writer.write_output(i * 0.001, "Event #{i}\r\n")
    end
  end
  raise "File not created" unless File.exist?(path)
  raise "File too small" unless File.size(path) > 100_000
end

suite.test("Read recording with 10,000 events") do
  path = suite.session.recording_path("large_recording")
  reader = AsciinemaWin::Asciicast.load(path)
  count = 0
  reader.each_event { |_| count += 1 }
  raise "Event count mismatch: #{count}" unless count == 10_000
end

suite.test("Recording with very long lines (10KB each)") do
  path = suite.session.recording_path("long_lines")
  AsciinemaWin::Asciicast.create(path, width: 200, height: 50) do |writer|
    100.times do |i|
      long_line = "X" * 10_000 + "\r\n"
      writer.write_output(i * 0.01, long_line)
    end
  end
  raise "File not created" unless File.exist?(path)
end

suite.test("Recording with Unicode content") do
  path = suite.session.recording_path("unicode")
  content = [
    "日本語テスト\r\n",
    "中文测试内容\r\n",
    "한국어 테스트\r\n",
    "Emoji: 🎉🎊🎁🎄🎅🌟\r\n",
    "Mixed: Hello 你好 👋\r\n"
  ]
  AsciinemaWin::Asciicast.create(path, width: 80, height: 24) do |writer|
    content.each_with_index do |line, i|
      writer.write_output(i * 0.1, line)
    end
  end
  info = AsciinemaWin::Asciicast::Reader.info(path)
  raise "Events not recorded" unless info[:event_count] == 5
end

suite.test("Recording with all ANSI color codes") do
  path = suite.session.recording_path("all_colors")
  AsciinemaWin::Asciicast.create(path, width: 80, height: 50) do |writer|
    time = 0.0
    # 16 colors
    (30..37).each { |c| writer.write_output(time += 0.01, "\e[#{c}m##\e[0m") }
    (90..97).each { |c| writer.write_output(time += 0.01, "\e[#{c}m##\e[0m") }
    writer.write_output(time += 0.01, "\r\n")
    
    # 256 colors
    (0..255).each do |c|
      writer.write_output(time += 0.001, "\e[38;5;#{c}m#\e[0m")
    end
    writer.write_output(time += 0.01, "\r\n")
    
    # RGB colors
    (0..255).step(16) do |r|
      writer.write_output(time += 0.001, "\e[38;2;#{r};0;0m#\e[0m")
    end
  end
  raise "File not created" unless File.exist?(path)
end

suite.test("Recording with resize events") do
  path = suite.session.recording_path("resize")
  AsciinemaWin::Asciicast.create(path, width: 80, height: 24) do |writer|
    writer.write_output(0.0, "Initial size\r\n")
    writer.write_resize(1.0, 120, 40)
    writer.write_output(1.5, "After resize\r\n")
    writer.write_resize(2.0, 80, 24)
    writer.write_output(2.5, "Back to original\r\n")
  end
  info = AsciinemaWin::Asciicast::Reader.info(path)
  raise "Events missing" unless info[:event_count] >= 5
end

suite.test("Recording with markers") do
  path = suite.session.recording_path("markers")
  AsciinemaWin::Asciicast.create(path, width: 80, height: 24) do |writer|
    writer.write_output(0.0, "Section 1\r\n")
    writer.write_marker(0.5, "section_1_end")
    writer.write_output(1.0, "Section 2\r\n")
    writer.write_marker(1.5, "section_2_end")
    writer.write_output(2.0, "Section 3\r\n")
    writer.write_marker(2.5, "complete")
  end
  raise "File not created" unless File.exist?(path)
end

# =============================================================================
# ANSI PARSER STRESS TESTS
# =============================================================================

suite.test("AnsiParser with 1000 lines") do
  parser = AsciinemaWin::AnsiParser.new(width: 80, height: 1000)
  content = (1..1000).map { |i| "Line #{i}: \e[32mGreen\e[0m \e[31mRed\e[0m\n" }.join
  lines = parser.parse(content)
  raise "Line count wrong: #{lines.length}" unless lines.length >= 1000
end

suite.test("AnsiParser with complex cursor movement") do
  parser = AsciinemaWin::AnsiParser.new(width: 80, height: 25)
  content = [
    "\e[2J\e[H",                    # Clear and home
    "Line 1\n",
    "\e[5;10H",                     # Move to row 5, col 10
    "Positioned text",
    "\e[A\e[A\e[A",                 # Move up 3
    "Above",
    "\e[10B\e[20C",                 # Down 10, right 20
    "Below and right",
    "\e[1;1H",                      # Back to top
    "Done"
  ].join
  lines = parser.parse(content)
  raise "Parse failed" if lines.empty?
end

suite.test("AnsiParser with all SGR attributes") do
  parser = AsciinemaWin::AnsiParser.new(width: 100, height: 10)
  content = [
    "\e[1mBold\e[0m ",
    "\e[3mItalic\e[0m ",
    "\e[4mUnderline\e[0m ",
    "\e[9mStrike\e[0m ",
    "\e[1;3;4;31mAll combined\e[0m"
  ].join
  lines = parser.parse(content)
  raise "Parse failed" if lines.empty?
end

suite.test("AnsiParser with 256 color palette") do
  parser = AsciinemaWin::AnsiParser.new(width: 256, height: 2)
  content = (0..255).map { |c| "\e[38;5;#{c}m#\e[0m" }.join
  lines = parser.parse(content)
  # Check some colors parsed correctly
  raise "Color 196 not parsed" unless lines[0].chars[196].fg == 196
end

suite.test("AnsiParser with RGB colors") do
  parser = AsciinemaWin::AnsiParser.new(width: 50, height: 2)
  content = "\e[38;2;255;128;64mRGB Orange\e[0m"
  lines = parser.parse(content)
  fg = lines[0].chars[0].fg
  raise "RGB not parsed correctly" unless fg == "#ff8040"
end

# =============================================================================
# EXPORT STRESS TESTS
# =============================================================================

suite.test("Export large recording to SVG") do
  source = suite.session.recording_path("large_recording")
  output = suite.session.export_path("large", format: :svg)
  AsciinemaWin::Export.export(source, output, format: :svg, theme: "dracula")
  raise "SVG not created" unless File.exist?(output)
  raise "SVG too small" unless File.size(output) > 1000
end

suite.test("Export to all 9 themes") do
  source = suite.session.recording_path("unicode")
  AsciinemaWin::Themes.names.each do |theme|
    output = suite.session.export_path("themed_#{theme}", format: :svg)
    AsciinemaWin::Export.export(source, output, format: :svg, theme: theme)
    raise "#{theme} export failed" unless File.exist?(output)
  end
end

suite.test("Export to HTML") do
  source = suite.session.recording_path("unicode")
  output = suite.session.export_path("test", format: :html)
  AsciinemaWin::Export.export(source, output, format: :html)
  content = File.read(output)
  raise "HTML missing player" unless content.include?("asciinema-player")
end

suite.test("Export to JSON") do
  source = suite.session.recording_path("unicode")
  output = suite.session.export_path("test", format: :json)
  AsciinemaWin::Export.export(source, output, format: :json)
  content = File.read(output)
  raise "JSON invalid" unless content.include?('"events"')
end

suite.test("Export to Text") do
  source = suite.session.recording_path("unicode")
  output = suite.session.export_path("test", format: :txt)
  AsciinemaWin::Export.export(source, output, format: :txt)
  content = File.read(output)
  # Should have stripped ANSI but kept Unicode
  raise "Text export failed" if content.empty?
end

# =============================================================================
# ADVANCED FEATURES STRESS TESTS
# =============================================================================

suite.test("Speed adjustment (0.5x to 4x)") do
  source = suite.session.recording_path("markers")
  [0.5, 1.0, 2.0, 4.0].each do |speed|
    output = suite.session.export_path("speed_#{speed}x", format: :cast)
    AsciinemaWin::Export.adjust_speed(source, output, speed: speed)
    
    orig = AsciinemaWin::Asciicast::Reader.info(source)
    adj = AsciinemaWin::Asciicast::Reader.info(output)
    expected_ratio = 1.0 / speed
    actual_ratio = adj[:duration] / orig[:duration]
    
    diff = (actual_ratio - expected_ratio).abs
    raise "Speed #{speed}x ratio wrong: #{actual_ratio}" if diff > 0.1
  end
end

suite.test("Idle compression") do
  # Create recording with idle time
  source = suite.session.recording_path("idle")
  AsciinemaWin::Asciicast.create(source, width: 80, height: 24) do |writer|
    writer.write_output(0.0, "Before pause\r\n")
    writer.write_output(10.0, "After 10s pause\r\n")  # 10 second gap
    writer.write_output(20.0, "After another 10s\r\n")
  end
  
  output = suite.session.export_path("compressed", format: :cast)
  AsciinemaWin::Export.adjust_speed(source, output, max_idle: 0.5)
  
  info = AsciinemaWin::Asciicast::Reader.info(output)
  raise "Compression failed: #{info[:duration]}" if info[:duration] > 2.0
end

suite.test("Concatenate 10 recordings") do
  # Create 10 small recordings
  paths = (1..10).map do |i|
    path = suite.session.recording_path("concat_part_#{i}")
    AsciinemaWin::Asciicast.create(path, width: 80, height: 24, title: "Part #{i}") do |writer|
      writer.write_output(0.0, "Part #{i} content\r\n")
      writer.write_output(0.5, "End of part #{i}\r\n")
    end
    path
  end
  
  output = suite.session.export_path("concatenated_10", format: :cast)
  AsciinemaWin::Export.concatenate(paths, output, gap: 0.2)
  
  info = AsciinemaWin::Asciicast::Reader.info(output)
  raise "Concatenation failed" unless info[:event_count] >= 20
end

suite.test("Thumbnail generation (all frame types)") do
  source = suite.session.recording_path("all_colors")
  
  [:first, :middle, :last].each do |frame|
    output = suite.session.thumbnail_path("colors", frame: frame)
    AsciinemaWin::Export.thumbnail(source, output, frame: frame, theme: "monokai")
    raise "#{frame} thumbnail not created" unless File.exist?(output)
  end
end

suite.test("Thumbnail at specific time") do
  source = suite.session.recording_path("markers")
  output = suite.session.thumbnail_path("at_time", frame: :last)
  AsciinemaWin::Export.thumbnail(source, output, frame: 1.5, theme: "dracula")
  raise "Time-based thumbnail failed" unless File.exist?(output)
end

# =============================================================================
# THEMES STRESS TESTS
# =============================================================================

suite.test("All themes have valid colors") do
  AsciinemaWin::Themes.names.each do |name|
    theme = AsciinemaWin::Themes.get(name)
    raise "#{name} missing foreground" unless theme.foreground =~ /^#[0-9a-f]{6}$/i
    raise "#{name} missing background" unless theme.background =~ /^#[0-9a-f]{6}$/i
    raise "#{name} missing palette" unless theme.palette.length == 16
  end
end

suite.test("Theme ANSI color resolution") do
  theme = AsciinemaWin::Themes.get("dracula")
  (0..15).each do |i|
    color = theme.color(i)
    raise "Color #{i} invalid" unless color =~ /^#[0-9a-f]{6}$/i
  end
end

# =============================================================================
# OUTPUT ORGANIZER STRESS TESTS
# =============================================================================

suite.test("Create 100 session paths") do
  (1..100).each do |i|
    path = AsciinemaWin::OutputOrganizer.output_path(
      "test_#{i}",
      format: :cast,
      base_dir: "asciinema_output",
      timestamp: false,
      session_id: suite.session.id
    )
    raise "Path #{i} invalid" if path.nil? || path.empty?
  end
end

suite.test("Session summary generation") do
  summary = suite.session.summary
  raise "Summary empty" if summary.nil? || summary.empty?
  raise "Summary missing session ID" unless summary.include?(suite.session.id)
end

# Run all tests
success = suite.run_all

puts "\nSession: #{suite.session.id}"
puts "Output: asciinema_output/"

exit(success ? 0 : 1)
