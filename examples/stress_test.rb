# frozen_string_literal: true

# Comprehensive stress tests for Rich library
# These tests push every component to its limits

require_relative "../lib/rich"

class StressTest
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

class StressTestSuite
  def initialize
    @tests = []
    @console = Rich::Console.new
  end

  def test(name, &block)
    @tests << StressTest.new(name, &block)
  end

  def run_all
    puts "=" * 70
    puts "Rich Library Stress Test Suite"
    puts "=" * 70
    puts ""

    @tests.each do |t|
      print "  #{t.name.ljust(50)}... "
      t.run
      if t.passed
        puts "✓ PASS (#{format('%.3f', t.duration)}s)"
      else
        puts "✗ FAIL"
        puts "    Error: #{t.error.message}"
        puts "    #{t.error.backtrace.first}"
      end
    end

    passed = @tests.count(&:passed)
    total = @tests.length
    total_time = @tests.sum(&:duration)

    puts ""
    puts "=" * 70
    puts "Results: #{passed}/#{total} tests passed in #{format('%.2f', total_time)}s"
    puts "=" * 70

    passed == total
  end
end

suite = StressTestSuite.new

# =============================================================================
# PART 1: COLOR SYSTEM STRESS TESTS
# =============================================================================

suite.test("Parse all 256 ANSI color names") do
  Rich::ANSI_COLOR_NAMES.each do |name, number|
    color = Rich::Color.parse(name)
    raise "#{name} parsed wrong" unless color.number == number
  end
end

suite.test("Parse 10,000 random hex colors") do
  10_000.times do
    r = rand(256)
    g = rand(256)
    b = rand(256)
    hex = format("#%02x%02x%02x", r, g, b)
    color = Rich::Color.parse(hex)
    raise "Hex parse failed" unless color.triplet.red == r
  end
end

suite.test("Color downgrade from truecolor to 256") do
  1000.times do
    triplet = Rich::ColorTriplet.new(rand(256), rand(256), rand(256))
    color = Rich::Color.from_triplet(triplet)
    downgraded = color.downgrade(Rich::ColorSystem::EIGHT_BIT)
    raise "Downgrade failed" unless downgraded.type == Rich::ColorType::EIGHT_BIT
  end
end

suite.test("Color downgrade from truecolor to 16") do
  1000.times do
    triplet = Rich::ColorTriplet.new(rand(256), rand(256), rand(256))
    color = Rich::Color.from_triplet(triplet)
    downgraded = color.downgrade(Rich::ColorSystem::STANDARD)
    raise "Downgrade failed" unless downgraded.number.between?(0, 15)
  end
end

suite.test("ColorTriplet HSL roundtrip") do
  100.times do
    h = rand(360)
    s = rand(100)
    l = rand(100)
    triplet = Rich::ColorTriplet.from_hsl(h, s, l)
    raise "HSL failed" unless triplet.red.between?(0, 255)
  end
end

suite.test("Color parse caching performance") do
  # Parse same colors many times - should be cached
  colors = %w[red green blue yellow magenta cyan white black]
  10_000.times do
    colors.each { |c| Rich::Color.parse(c) }
  end
end

# =============================================================================
# PART 2: STYLE SYSTEM STRESS TESTS
# =============================================================================

suite.test("Parse complex style definitions") do
  styles = [
    "bold italic underline red on blue",
    "dim reverse strike conceal",
    "not bold underline2 frame encircle overline",
    "bright_magenta on bright_cyan blink",
    "#ff5500 on #00ff55 bold italic"
  ]
  styles.each do |s|
    style = Rich::Style.parse(s)
    raise "Parse failed for: #{s}" if style.nil?
  end
end

suite.test("Style combination chain (1000 styles)") do
  base = Rich::Style.parse("bold")
  1000.times do |i|
    color_style = Rich::Style.parse("color(#{i % 256})")
    base = base + color_style
  end
  raise "Combination failed" unless base.bold?
end

suite.test("Style attribute bitmask integrity") do
  Rich::StyleAttribute::NAMES.each do |attr|
    style = Rich::Style.new(**{ attr => true })
    raise "#{attr} not set" unless style.send("#{attr}?")
  end
end

suite.test("Style render with all attributes") do
  style = Rich::Style.new(
    color: "red",
    bgcolor: "blue",
    bold: true,
    italic: true,
    underline: true,
    strike: true
  )
  rendered = style.render
  raise "Render empty" if rendered.empty?
  raise "No escape" unless rendered.include?("\e[")
end

# =============================================================================
# PART 3: UNICODE AND CELL WIDTH STRESS TESTS
# =============================================================================

suite.test("CJK character width calculation") do
  cjk_strings = [
    "你好世界",           # Chinese
    "こんにちは",         # Japanese Hiragana
    "안녕하세요",         # Korean
    "漢字カタカナ한글",   # Mixed
    "🎉🎊🎁🎄🎅"          # Emoji
  ]
  cjk_strings.each do |s|
    width = Rich::Cells.cell_len(s)
    # CJK and emoji are generally 2 cells wide
    raise "Width wrong for: #{s}" unless width >= s.length
  end
end

suite.test("Zero-width combining characters") do
  # Combining marks should have zero width
  combining = "é"  # e + combining acute
  base_width = Rich::Cells.cell_len("e")
  # The combined char width should account for combining marks
  combined_width = Rich::Cells.cell_len(combining)
  raise "Combining failed" if combined_width < 0
end

suite.test("Mixed ASCII and Unicode") do
  text = "Hello 你好 World 世界 123"
  width = Rich::Cells.cell_len(text)
  # ASCII=14, CJK=4chars*2=8, total should be 22+
  raise "Mixed width failed" unless width >= 20
end

suite.test("Large Unicode string (10KB)") do
  # Generate 10KB of mixed Unicode
  chars = "ABCあいう你好世界🎉".chars
  text = (0...10_000).map { chars.sample }.join
  width = Rich::Cells.cell_len(text)
  raise "Large string failed" unless width > 0
end

suite.test("Empty and whitespace strings") do
  raise "Empty failed" unless Rich::Cells.cell_len("") == 0
  raise "Space failed" unless Rich::Cells.cell_len(" ") == 1
  raise "Tab failed" unless Rich::Cells.cell_len("\t") == 1
  raise "Newline failed" unless Rich::Cells.cell_len("\n") == 1
end

# =============================================================================
# PART 4: SEGMENT SYSTEM STRESS TESTS
# =============================================================================

suite.test("Segment split at every position") do
  text = "Hello World"
  style = Rich::Style.parse("bold red")
  segment = Rich::Segment.new(text, style: style)

  (0..text.length).each do |pos|
    before, after = segment.split_cells(pos)
    combined = before.text + after.text
    raise "Split failed at #{pos}" unless combined == text
  end
end

suite.test("Segment line splitting with many newlines") do
  segments = [
    Rich::Segment.new("Line1\nLine2\nLine3\n\nLine5"),
    Rich::Segment.new("More\nLines\nHere")
  ]
  lines = Rich::Segment.split_lines(segments)
  raise "Line count wrong" unless lines.length >= 6
end

suite.test("Segment simplification (1000 segments)") do
  style = Rich::Style.parse("bold")
  segments = 1000.times.map { Rich::Segment.new("x", style: style) }
  simplified = Rich::Segment.simplify(segments)
  raise "Not simplified" unless simplified.length < segments.length
end

suite.test("Segment rendering with control codes") do
  segments = [
    Rich::Segment.control([[Rich::Control::ControlType::HIDE_CURSOR]]),
    Rich::Segment.new("Content", style: Rich::Style.parse("green")),
    Rich::Segment.control([[Rich::Control::ControlType::SHOW_CURSOR]])
  ]
  output = Rich::Segment.render(segments)
  raise "Control not rendered" unless output.include?("\e[?25l")
end

# =============================================================================
# PART 5: TEXT AND MARKUP STRESS TESTS
# =============================================================================

suite.test("Text with 1000 overlapping spans") do
  text = Rich::Text.new("A" * 1000)
  1000.times do |i|
    text.stylize("bold", i, i + 50)
  end
  segments = text.to_segments
  raise "No segments" if segments.empty?
end

suite.test("Deeply nested markup") do
  nested = "[bold][italic][underline][red][on blue]Deep[/on blue][/red][/underline][/italic][/bold]"
  text = Rich::Markup.parse(nested)
  raise "Parse failed" if text.plain != "Deep"
end

suite.test("Markup validation with errors") do
  invalid = "[bold]unclosed"
  errors = Rich::Markup.validate(invalid)
  raise "Should have errors" if errors.empty?

  valid = "[bold]closed[/bold]"
  errors = Rich::Markup.validate(valid)
  raise "Should be valid" unless errors.empty?
end

suite.test("Text wrapping at various widths") do
  text = Rich::Text.new("Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 10)
  [10, 20, 40, 80, 120].each do |width|
    wrapped = text.wrap(width)
    raise "Wrap failed at #{width}" if wrapped.empty?
  end
end

suite.test("Text with special characters") do
  specials = "Tab:\tNewline:\nCarriage:\rBackslash:\\"
  text = Rich::Text.new(specials)
  text.stylize("bold", 0, specials.length)
  segments = text.to_segments
  raise "Special chars failed" if segments.empty?
end

# =============================================================================
# PART 6: LAYOUT COMPONENT STRESS TESTS
# =============================================================================

suite.test("Panel with very long content") do
  content = "X" * 1000
  panel = Rich::Panel.new(content, title: "Long Content")
  output = panel.render(max_width: 80)
  raise "Panel failed" if output.empty?
end

suite.test("Panel with Unicode borders and content") do
  content = "こんにちは世界"
  panel = Rich::Panel.new(content, title: "日本語", box: Rich::Box::DOUBLE)
  output = panel.render(max_width: 40)
  raise "Unicode panel failed" if output.empty?
end

suite.test("Table with 100 rows") do
  table = Rich::Table.new(title: "Large Table")
  table.add_column("ID", justify: :right)
  table.add_column("Name")
  table.add_column("Value", justify: :center)

  100.times do |i|
    table.add_row(i.to_s, "Item #{i}", format("%.2f", rand * 1000))
  end

  output = table.render(max_width: 80)
  raise "Large table failed" if output.empty?
end

suite.test("Table with Unicode content") do
  table = Rich::Table.new(box: Rich::Box::HEAVY)
  table.add_column("Language")
  table.add_column("Greeting")
  table.add_row("日本語", "こんにちは")
  table.add_row("中文", "你好")
  table.add_row("한국어", "안녕하세요")
  table.add_row("Emoji", "👋🌍🎉")

  output = table.render(max_width: 60)
  raise "Unicode table failed" if output.empty?
end

suite.test("Tree with deep nesting (10 levels)") do
  tree = Rich::Tree.new("Root")
  current = tree.root
  10.times do |i|
    current = current.add("Level #{i + 1}")
  end
  output = tree.render
  raise "Deep tree failed" unless output.include?("Level 10")
end

suite.test("Tree with many siblings (100)") do
  tree = Rich::Tree.new("Root")
  100.times do |i|
    tree.add("Child #{i}")
  end
  output = tree.render
  raise "Wide tree failed" unless output.lines.length >= 100
end

suite.test("All box styles render correctly") do
  boxes = [
    Rich::Box::ASCII,
    Rich::Box::SQUARE,
    Rich::Box::ROUNDED,
    Rich::Box::HEAVY,
    Rich::Box::DOUBLE,
    Rich::Box::MINIMAL,
    Rich::Box::SIMPLE
  ]
  boxes.each do |box|
    panel = Rich::Panel.new("Content", box: box)
    output = panel.render(max_width: 30)
    raise "Box style failed" if output.empty?
  end
end

# =============================================================================
# PART 7: PROGRESS AND ANIMATION STRESS TESTS
# =============================================================================

suite.test("Progress bar at every percentage") do
  bar = Rich::ProgressBar.new(total: 100)
  101.times do |i|
    bar.update(i)
    raise "Percentage wrong" unless bar.percentage == i
  end
end

suite.test("Progress bar with very large total") do
  bar = Rich::ProgressBar.new(total: 1_000_000_000)
  bar.update(500_000_000)
  raise "Large total failed" unless bar.percentage == 50
end

suite.test("Spinner cycles through all frames") do
  spinner = Rich::Spinner.new(frames: Rich::ProgressStyle::DOTS)
  seen_frames = Set.new
  100.times do
    seen_frames.add(spinner.frame)
    spinner.advance
  end
  raise "Not all frames" unless seen_frames.length == Rich::ProgressStyle::DOTS.length
end

suite.test("Multiple spinner styles") do
  styles = [
    Rich::ProgressStyle::DOTS,
    Rich::ProgressStyle::LINE,
    Rich::ProgressStyle::CIRCLE,
    Rich::ProgressStyle::BOUNCE
  ]
  styles.each do |frames|
    spinner = Rich::Spinner.new(frames: frames)
    5.times { spinner.advance }
  end
end

# =============================================================================
# PART 8: JSON AND PRETTY PRINTING STRESS TESTS
# =============================================================================

suite.test("JSON with deeply nested structure") do
  data = { "level" => nil }
  current = data
  20.times do |i|
    current["nested"] = { "level" => i }
    current = current["nested"]
  end
  output = Rich::JSON.to_s(data)
  raise "Deep JSON failed" if output.empty?
end

suite.test("JSON with large array") do
  data = (0...1000).to_a
  output = Rich::JSON.to_s(data)
  raise "Large array failed" if output.empty?
end

suite.test("JSON with special characters") do
  data = {
    "unicode" => "こんにちは 🎉",
    "escapes" => "Line1\nLine2\tTabbed",
    "quotes" => 'He said "hello"'
  }
  output = Rich::JSON.to_s(data)
  raise "Special JSON failed" if output.empty?
end

suite.test("Pretty print complex Ruby object") do
  data = {
    string: "hello",
    number: 42,
    float: 3.14159,
    bool: true,
    nil_val: nil,
    array: [1, 2, [3, 4]],
    hash: { nested: { deep: "value" } },
    symbol: :test
  }
  output = Rich::Pretty.to_s(data)
  raise "Pretty print failed" if output.empty?
end

# =============================================================================
# PART 9: CONSOLE AND RENDERING STRESS TESTS
# =============================================================================

suite.test("Console size detection") do
  console = Rich::Console.new
  raise "No width" unless console.width > 0
  raise "No height" unless console.height > 0
  raise "No color system" unless Rich::ColorSystem::ALL.include?(console.color_system)
end

suite.test("Console options update") do
  options = Rich::ConsoleOptions.new(max_width: 80)
  updated = options.update(max_width: 120)
  raise "Update failed" unless updated.max_width == 120
  raise "Original changed" unless options.max_width == 80
end

suite.test("Control codes generate valid ANSI") do
  codes = [
    Rich::Control.clear_screen,
    Rich::Control.cursor_up(5),
    Rich::Control.cursor_down(5),
    Rich::Control.cursor_forward(10),
    Rich::Control.cursor_backward(10),
    Rich::Control.cursor_move_to(10, 20),
    Rich::Control.set_title("Test"),
    Rich::Control.hide_cursor,
    Rich::Control.show_cursor,
    Rich::Control.hyperlink("https://example.com", "Link")
  ]
  codes.each do |code|
    raise "Invalid control code" if code.nil?
  end
end

suite.test("ANSI stripping") do
  styled = "\e[1;31mHello\e[0m \e[32mWorld\e[0m"
  stripped = Rich::Control.strip_ansi(styled)
  raise "Strip failed" unless stripped == "Hello World"
end

# =============================================================================
# PART 10: WINDOWS CONSOLE API TESTS (Windows only)
# =============================================================================

if Gem.win_platform?
  suite.test("Windows Console API functions available") do
    methods = %i[
      stdout_handle
      get_console_mode
      set_console_mode
      supports_ansi?
      get_size
      get_cursor_position
    ]
    methods.each do |method|
      raise "Missing #{method}" unless Rich::Win32Console.respond_to?(method)
    end
  end

  suite.test("Windows ANSI support detection") do
    result = Rich::Win32Console.supports_ansi?
    raise "Must be boolean" unless [true, false].include?(result)
  end

  suite.test("Windows console size valid") do
    size = Rich::Win32Console.get_size
    raise "Size failed" unless size && size[0] > 0 && size[1] > 0
  end
end

# =============================================================================
# PART 11: EDGE CASES AND BOUNDARY CONDITIONS
# =============================================================================

suite.test("Empty inputs handled gracefully") do
  # These should not raise
  Rich::Color.parse("default")
  Rich::Style.parse("")
  Rich::Text.new("")
  Rich::Markup.parse("")
  Rich::Panel.new("")
  Rich::Table.new
  Rich::Tree.new("")
end

suite.test("Nil inputs handled gracefully") do
  Rich::Style.parse(nil)
  Rich::Style.null + nil
  Rich::Segment.new(nil.to_s)
end

suite.test("Very long single-line content") do
  content = "X" * 10_000
  text = Rich::Text.new(content)
  text.stylize("bold", 0, 5000)
  segments = text.to_segments
  raise "Long content failed" if segments.empty?
end

suite.test("Content at exact width boundary") do
  # Panel with content exactly at boundary
  panel = Rich::Panel.new("X" * 18, padding: 0)
  output = panel.render(max_width: 20)
  raise "Boundary failed" if output.empty?
end

suite.test("Zero and negative values") do
  Rich::ProgressBar.new(total: 0)
  Rich::ProgressBar.new(total: 1, completed: -5)  # Should clamp
  text = Rich::Text.new("test")
  text.wrap(0)  # Should handle gracefully
end

# Run all tests
success = suite.run_all
exit(success ? 0 : 1)
