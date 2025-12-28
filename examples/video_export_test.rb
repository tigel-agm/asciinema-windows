# frozen_string_literal: true

# Video Export Test Suite
#
# Comprehensive tests for FFmpeg-based video export (GIF, MP4, WebM).
# Tests edge cases, error handling, and all supported options.

require_relative "../lib/asciinema_win"

module VideoExportTest
  extend self

  # Test results tracking
  @passed = 0
  @failed = 0
  @errors = []

  # ANSI colors for output
  COLORS = {
    reset: "\e[0m",
    green: "\e[32m",
    red: "\e[31m",
    yellow: "\e[33m",
    cyan: "\e[36m",
    bold: "\e[1m"
  }.freeze

  def run_all
    puts "#{COLORS[:bold]}#{COLORS[:cyan]}═" * 70
    puts "Video Export Test Suite"
    puts "═" * 70 + COLORS[:reset]
    puts

    # Create test recording
    setup_test_files

    # Run test categories
    run_category("FFmpeg Availability") { test_ffmpeg_availability }
    run_category("GIF Export") { test_gif_export }
    run_category("MP4 Export") { test_mp4_export }
    run_category("WebM Export") { test_webm_export }
    run_category("Export Options") { test_export_options }
    run_category("Error Handling") { test_error_handling }
    run_category("Theme Support") { test_theme_support }
    run_category("Edge Cases") { test_edge_cases }

    # Cleanup
    cleanup_test_files

    # Print summary
    print_summary
  end

  private

  def setup_test_files
    @test_dir = File.join(Dir.tmpdir, "asciinema_win_video_test_#{Process.pid}")
    FileUtils.mkdir_p(@test_dir)

    # Create a simple test recording
    @test_cast = File.join(@test_dir, "test.cast")
    AsciinemaWin::Asciicast.create(@test_cast, width: 40, height: 10, title: "Video Export Test") do |writer|
      writer.write_output(0.0, "\e[1;32mVideo Export Test\e[0m\r\n")
      writer.write_output(0.5, "Testing GIF/MP4/WebM export...\r\n")
      writer.write_output(1.0, "\e[34mBlue text\e[0m \e[31mRed text\e[0m\r\n")
      writer.write_output(1.5, "Frame 1 -> Frame 2 -> Frame 3\r\n")
      writer.write_output(2.0, "\e[1;33mComplete!\e[0m\r\n")
    end

    # Create minimal recording (edge case)
    @minimal_cast = File.join(@test_dir, "minimal.cast")
    AsciinemaWin::Asciicast.create(@minimal_cast, width: 20, height: 5) do |writer|
      writer.write_output(0.0, "X")
    end

    # Create empty recording (edge case)
    @empty_cast = File.join(@test_dir, "empty.cast")
    AsciinemaWin::Asciicast.create(@empty_cast, width: 20, height: 5) do |_writer|
      # No events
    end
  end

  def cleanup_test_files
    FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
  end

  def run_category(name)
    puts "#{COLORS[:bold]}▶ #{name}#{COLORS[:reset]}"
    yield
    puts
  end

  def test(description)
    result = yield
    if result
      @passed += 1
      puts "  #{COLORS[:green]}✓#{COLORS[:reset]} #{description}"
    else
      @failed += 1
      @errors << description
      puts "  #{COLORS[:red]}✗#{COLORS[:reset]} #{description}"
    end
  rescue StandardError => e
    @failed += 1
    @errors << "#{description}: #{e.message}"
    puts "  #{COLORS[:red]}✗#{COLORS[:reset]} #{description}"
    puts "    #{COLORS[:yellow]}Error: #{e.message}#{COLORS[:reset]}"
  end

  # ─────────────────────────────────────────────────────────────────
  # Test Categories
  # ─────────────────────────────────────────────────────────────────

  def test_ffmpeg_availability
    test("FFmpeg is available in PATH") do
      AsciinemaWin::Export.ffmpeg_available?
    end

    test("FFmpeg version can be detected") do
      output = `ffmpeg -version 2>&1`
      output.include?("ffmpeg version")
    end
  end

  def test_gif_export
    gif_path = File.join(@test_dir, "output.gif")

    test("Export recording to GIF") do
      AsciinemaWin::Export.export(@test_cast, gif_path, format: :gif, fps: 5)
      File.exist?(gif_path) && File.size(gif_path) > 0
    end

    test("GIF file has valid header") do
      data = File.binread(gif_path, 6)
      data == "GIF89a" || data == "GIF87a"
    end

    test("GIF with custom FPS (15)") do
      path = File.join(@test_dir, "output_15fps.gif")
      AsciinemaWin::Export.export(@test_cast, path, format: :gif, fps: 15)
      File.exist?(path) && File.size(path) > 0
    end
  end

  def test_mp4_export
    mp4_path = File.join(@test_dir, "output.mp4")

    test("Export recording to MP4") do
      AsciinemaWin::Export.export(@test_cast, mp4_path, format: :mp4, fps: 10)
      File.exist?(mp4_path) && File.size(mp4_path) > 0
    end

    test("MP4 file has valid header (ftyp)") do
      data = File.binread(mp4_path, 12)
      data[4..7] == "ftyp"
    end

    test("MP4 with custom FPS (30)") do
      path = File.join(@test_dir, "output_30fps.mp4")
      AsciinemaWin::Export.export(@test_cast, path, format: :mp4, fps: 30)
      File.exist?(path)
    end
  end

  def test_webm_export
    webm_path = File.join(@test_dir, "output.webm")

    test("Export recording to WebM") do
      AsciinemaWin::Export.export(@test_cast, webm_path, format: :webm, fps: 10)
      File.exist?(webm_path) && File.size(webm_path) > 0
    end

    test("WebM file has valid header") do
      data = File.binread(webm_path, 4)
      # WebM starts with EBML header (0x1A45DFA3)
      data[0].ord == 0x1A
    end
  end

  def test_export_options
    test("Export with theme: dracula") do
      path = File.join(@test_dir, "dracula.gif")
      AsciinemaWin::Export.export(@test_cast, path, format: :gif, fps: 5, theme: "dracula")
      File.exist?(path)
    end

    test("Export with low FPS (2)") do
      path = File.join(@test_dir, "low_fps.gif")
      AsciinemaWin::Export.export(@test_cast, path, format: :gif, fps: 2)
      File.exist?(path)
    end

    test("Export with high FPS (30)") do
      path = File.join(@test_dir, "high_fps.gif")
      AsciinemaWin::Export.export(@test_cast, path, format: :gif, fps: 30)
      File.exist?(path)
    end
  end

  def test_error_handling
    test("Raises error for non-existent input file") do
      begin
        AsciinemaWin::Export.export("/nonexistent/file.cast", "out.gif", format: :gif)
        false
      rescue StandardError
        true
      end
    end

    test("Raises error for unsupported format") do
      begin
        AsciinemaWin::Export.export(@test_cast, "out.xyz", format: :xyz)
        false
      rescue AsciinemaWin::ExportError
        true
      end
    end
  end

  def test_theme_support
    themes = %w[asciinema dracula monokai nord tokyo-night]

    themes.each do |theme|
      test("Export with theme: #{theme}") do
        path = File.join(@test_dir, "theme_#{theme}.gif")
        AsciinemaWin::Export.export(@test_cast, path, format: :gif, fps: 5, theme: theme)
        File.exist?(path)
      end
    end
  end

  def test_edge_cases
    test("Export minimal recording (single character)") do
      path = File.join(@test_dir, "minimal.gif")
      AsciinemaWin::Export.export(@minimal_cast, path, format: :gif, fps: 5)
      File.exist?(path)
    end

    test("Handle recording with no output events gracefully") do
      path = File.join(@test_dir, "empty.gif")
      begin
        AsciinemaWin::Export.export(@empty_cast, path, format: :gif, fps: 5)
        # Should either succeed with blank frames or raise an error
        true
      rescue AsciinemaWin::ExportError => e
        e.message.include?("No frames")
      end
    end

    test("Export to path with spaces") do
      dir = File.join(@test_dir, "path with spaces")
      FileUtils.mkdir_p(dir)
      path = File.join(dir, "output.gif")
      AsciinemaWin::Export.export(@test_cast, path, format: :gif, fps: 5)
      File.exist?(path)
    end
  end

  def print_summary
    total = @passed + @failed
    puts "#{COLORS[:bold]}═" * 70
    puts "Results: #{@passed}/#{total} tests passed"
    puts "═" * 70 + COLORS[:reset]

    if @failed > 0
      puts
      puts "#{COLORS[:red]}Failed tests:#{COLORS[:reset]}"
      @errors.each { |e| puts "  • #{e}" }
    end

    puts
    exit(@failed > 0 ? 1 : 0)
  end
end

# Run tests if executed directly
VideoExportTest.run_all if __FILE__ == $PROGRAM_NAME
