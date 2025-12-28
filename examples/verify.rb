# frozen_string_literal: true

# Full verification test for the Rich library

require_relative "../lib/rich"

puts "=" * 60
puts "Rich Library Verification Test"
puts "=" * 60
puts ""

# Track results
results = []

def test(name)
  print "Testing #{name}... "
  begin
    yield
    puts "✓ PASS"
    true
  rescue StandardError => e
    puts "✗ FAIL: #{e.message}"
    false
  end
end

# Test 1: Basic imports
results << test("Module loading") do
  raise "Console not defined" unless defined?(Rich::Console)
  raise "Color not defined" unless defined?(Rich::Color)
  raise "Style not defined" unless defined?(Rich::Style)
  raise "Text not defined" unless defined?(Rich::Text)
  raise "Panel not defined" unless defined?(Rich::Panel)
  raise "Table not defined" unless defined?(Rich::Table)
  raise "Tree not defined" unless defined?(Rich::Tree)
  raise "Progress not defined" unless defined?(Rich::ProgressBar)
end

# Test 2: ColorTriplet
results << test("ColorTriplet") do
  triplet = Rich::ColorTriplet.new(255, 128, 64)
  raise "Hex wrong" unless triplet.hex == "#ff8040"
  raise "RGB wrong" unless triplet.red == 255 && triplet.green == 128
  
  from_hex = Rich::ColorTriplet.from_hex("#00ff00")
  raise "From hex wrong" unless from_hex.green == 255
end

# Test 3: Color parsing
results << test("Color parsing") do
  red = Rich::Color.parse("red")
  raise "Red not parsed" unless red.type == Rich::ColorType::STANDARD
  
  hex = Rich::Color.parse("#ff5500")
  raise "Hex not parsed" unless hex.type == Rich::ColorType::TRUECOLOR
  
  named = Rich::Color.parse("bright_blue")
  raise "Named not parsed" unless named.number == 12
end

# Test 4: Style parsing
results << test("Style parsing") do
  style = Rich::Style.parse("bold red on white")
  raise "Bold not set" unless style.bold?
  raise "Color wrong" unless style.color.name == "red"
  raise "Bgcolor wrong" unless style.bgcolor.name == "white"
end

# Test 5: Style combination
results << test("Style combination") do
  s1 = Rich::Style.parse("bold")
  s2 = Rich::Style.parse("red")
  combined = s1 + s2
  raise "Combination failed" unless combined.bold? && combined.color.name == "red"
end

# Test 6: Console creation
results << test("Console creation") do
  console = Rich::Console.new
  raise "Width missing" unless console.width > 0
  raise "Height missing" unless console.height > 0
  raise "Color system missing" unless Rich::ColorSystem::ALL.include?(console.color_system)
end

# Test 7: Cell width calculation
results << test("Cell width calculation") do
  raise "ASCII wrong" unless Rich::Cells.cell_len("Hello") == 5
  raise "CJK wrong" unless Rich::Cells.cell_len("你好") == 4  # 2 chars × 2 width
  raise "Empty wrong" unless Rich::Cells.cell_len("") == 0
end

# Test 8: Segment creation
results << test("Segment creation") do
  seg = Rich::Segment.new("Hello", style: Rich::Style.parse("bold"))
  raise "Text wrong" unless seg.text == "Hello"
  raise "Style missing" unless seg.style.bold?
end

# Test 9: Text with spans
results << test("Text with spans") do
  text = Rich::Text.new("Hello ")
  text.append("World", style: "red")
  raise "Plain wrong" unless text.plain == "Hello World"
  raise "Spans wrong" unless text.spans.length == 1
end

# Test 10: Markup parsing
results << test("Markup parsing") do
  text = Rich::Markup.parse("[bold]Hello[/bold]")
  raise "Parse failed" unless text.plain == "Hello"
  raise "Style not applied" unless text.spans.any? { |s| s.style.bold? }
end

# Test 11: Panel rendering
results << test("Panel rendering") do
  panel = Rich::Panel.new("Content", title: "Title")
  output = panel.render(max_width: 40)
  raise "No border" unless output.include?("╭") || output.include?("+")
  raise "No content" unless output.include?("Content")
end

# Test 12: Table rendering
results << test("Table rendering") do
  table = Rich::Table.new
  table.add_column("Name")
  table.add_column("Value")
  table.add_row("Key", "123")
  output = table.render(max_width: 40)
  raise "No header" unless output.include?("Name")
  raise "No data" unless output.include?("123")
end

# Test 13: Tree rendering
results << test("Tree rendering") do
  tree = Rich::Tree.new("Root")
  tree.add("Child 1")
  tree.add("Child 2")
  output = tree.render
  raise "No root" unless output.include?("Root")
  raise "No children" unless output.include?("Child")
end

# Test 14: Progress bar
results << test("Progress bar") do
  bar = Rich::ProgressBar.new(total: 100, completed: 50)
  raise "Progress wrong" unless bar.progress == 0.5
  raise "Percentage wrong" unless bar.percentage == 50
  
  bar.advance(25)
  raise "Advance failed" unless bar.percentage == 75
end

# Test 15: Spinner
results << test("Spinner") do
  spinner = Rich::Spinner.new
  frame1 = spinner.frame
  spinner.advance
  frame2 = spinner.frame
  raise "Spinner not advancing" if frame1 == frame2 && spinner.frames.length > 1
end

# Test 16: Box styles
results << test("Box styles") do
  boxes = [Rich::Box::ASCII, Rich::Box::ROUNDED, Rich::Box::HEAVY, Rich::Box::DOUBLE]
  boxes.each do |box|
    raise "Missing top_left" if box.top_left.nil?
    raise "Missing horizontal" if box.horizontal.nil?
  end
end

# Test 17: JSON highlighting
results << test("JSON highlighting") do
  data = { "name" => "test", "value" => 123 }
  output = Rich::JSON.to_s(data)
  raise "No output" if output.empty?
end

# Test 18: Columns layout
results << test("Columns layout") do
  cols = Rich::Columns.new(%w[one two three four])
  output = cols.render(max_width: 40)
  raise "No content" unless output.include?("one")
end

# Test 19: Windows Console API (on Windows)
if Gem.win_platform?
  results << test("Windows Console API") do
    raise "Win32Console not loaded" unless defined?(Rich::Win32Console)
    raise "supports_ansi? missing" unless Rich::Win32Console.respond_to?(:supports_ansi?)
    
    # Get console size
    size = Rich::Win32Console.get_size
    raise "Size detection failed" unless size && size[0] > 0
  end
end

# Test 20: Control codes
results << test("Control codes") do
  raise "Clear missing" if Rich::Control.clear_screen.empty?
  raise "Cursor up missing" if Rich::Control.cursor_up(5).empty?
  raise "Reset missing" if Rich::Control.reset.empty?
end

puts ""
puts "=" * 60
passed = results.count(true)
total = results.length
puts "Results: #{passed}/#{total} tests passed"
puts "=" * 60

if passed == total
  puts "\n🎉 All tests passed! Rich library is fully functional."
else
  puts "\n⚠️  Some tests failed. Please review the output above."
end
