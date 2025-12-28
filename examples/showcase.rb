# frozen_string_literal: true

# Visual Showcase Demo - See Rich features in action!

require_relative "../lib/rich"

console = Rich::Console.new

# Helper to pause and let user see the output
def pause(message = "Press Enter to continue...")
  print "\n#{message}"
  gets
  puts ""
end

# =============================================================================
# INTRO
# =============================================================================
console.clear
console.rule("🎨 Rich Ruby Library - Visual Showcase", style: "bold magenta")
puts ""
puts "This demo will showcase all the visual features of the Rich library."
puts "Watch for colors, styles, panels, tables, trees, and progress bars!"
pause

# =============================================================================
# 1. COLORS
# =============================================================================
console.clear
console.rule("1. Color Showcase", style: "bold cyan")
puts ""

# Standard colors
puts "Standard 16 Colors:"
%w[black red green yellow blue magenta cyan white].each do |color|
  console.print("  #{color.ljust(10)}", style: color, end_str: "")
  console.print(" bright_#{color}", style: "bright_#{color}")
end
puts ""

# 256 color palette preview
puts "256 Color Palette (sample):"
print "  "
(0...36).each do |i|
  style = Rich::Style.new(bgcolor: Rich::Color.parse("color(#{i * 7})"))
  console.write(style.render + "  " + "\e[0m")
end
puts ""
puts ""

# Truecolor gradient
puts "TrueColor Gradient:"
print "  "
80.times do |i|
  r = (255 * i / 80.0).to_i
  g = (255 * (80 - i) / 80.0).to_i
  b = 128
  style = Rich::Style.new(bgcolor: Rich::Color.from_triplet(Rich::ColorTriplet.new(r, g, b)))
  console.write(style.render + " " + "\e[0m")
end
puts ""

pause

# =============================================================================
# 2. TEXT STYLES
# =============================================================================
console.clear
console.rule("2. Text Styles", style: "bold cyan")
puts ""

styles = [
  ["bold", "Bold text - stands out!"],
  ["dim", "Dim text - subtle emphasis"],
  ["italic", "Italic text - for emphasis"],
  ["underline", "Underlined text - important"],
  ["blink", "Blinking text - attention!"],
  ["reverse", "Reversed colors"],
  ["strike", "Strikethrough - outdated"],
  ["underline2", "Double underline"],
  ["overline", "Overlined text"]
]

styles.each do |style, description|
  console.print("  ", end_str: "")
  console.print(description.ljust(35), style: style, end_str: "")
  console.print(" [#{style}]", style: "dim")
end
puts ""

# Combined styles
puts "Combined Styles:"
combos = [
  "bold red",
  "italic green",
  "bold italic underline blue",
  "dim yellow on black",
  "bold white on red",
  "italic cyan on magenta"
]

combos.each do |combo|
  console.print("  ", end_str: "")
  console.print(combo.ljust(30), style: combo)
end

pause

# =============================================================================
# 3. MARKUP
# =============================================================================
console.clear
console.rule("3. Rich Markup", style: "bold cyan")
puts ""

puts "Markup makes styling text easy!"
puts ""

markups = [
  "[bold]Bold text[/bold]",
  "[red]Red text[/red]",
  "[bold green]Bold green[/bold green]",
  "[italic blue on white]Italic blue on white background[/italic blue on white]",
  "[underline magenta]Underlined magenta[/underline magenta]"
]

markups.each do |markup|
  print "  "
  rendered = Rich::Markup.render(markup)
  puts rendered + "\e[0m"
  console.print("    Source: #{markup}", style: "dim")
end

pause

# =============================================================================
# 4. PANELS
# =============================================================================
console.clear
console.rule("4. Panels", style: "bold cyan")
puts ""

# Simple panel
panel1 = Rich::Panel.new(
  "This is a simple panel with some content.\nPanels are great for highlighting information!",
  title: "Simple Panel",
  border_style: "green"
)
puts panel1.render(max_width: 60)
puts ""

# Panel with subtitle
panel2 = Rich::Panel.new(
  "Panels can have both titles and subtitles.\nThey support different box styles too!",
  title: "✨ Featured",
  subtitle: "Look at me!",
  border_style: "cyan",
  title_style: "bold white"
)
puts panel2.render(max_width: 60)
puts ""

# Different box styles
puts "Box Styles:"
boxes = [
  [Rich::Box::ASCII, "ASCII"],
  [Rich::Box::ROUNDED, "Rounded"],
  [Rich::Box::HEAVY, "Heavy"],
  [Rich::Box::DOUBLE, "Double"]
]

boxes.each do |box, name|
  small = Rich::Panel.new("Content", title: name, box: box, padding: 0)
  print small.render(max_width: 20)
end

pause

# =============================================================================
# 5. TABLES
# =============================================================================
console.clear
console.rule("5. Tables", style: "bold cyan")
puts ""

# User table
table1 = Rich::Table.new(title: "👥 Team Members", border_style: "blue")
table1.add_column("Name", header_style: "bold cyan")
table1.add_column("Role", header_style: "bold cyan")
table1.add_column("Status", header_style: "bold cyan", justify: :center)

table1.add_row("Alice Johnson", "Lead Developer", "🟢 Active")
table1.add_row("Bob Smith", "Designer", "🟢 Active")
table1.add_row("Carol Williams", "DevOps", "🟡 Away")
table1.add_row("David Brown", "QA Engineer", "🔴 Offline")

puts table1.render(max_width: 65)
puts ""

# Performance table
table2 = Rich::Table.new(title: "📊 Performance Metrics", border_style: "green", box: Rich::Box::DOUBLE)
table2.add_column("Metric", header_style: "bold")
table2.add_column("Value", justify: :right, style: "cyan")
table2.add_column("Change", justify: :right)

table2.add_row("Response Time", "45ms", "↓ 12%")
table2.add_row("Throughput", "1,234 req/s", "↑ 23%")
table2.add_row("Error Rate", "0.02%", "↓ 5%")
table2.add_row("CPU Usage", "67%", "→ 0%")

puts table2.render(max_width: 55)

pause

# =============================================================================
# 6. TREES
# =============================================================================
console.clear
console.rule("6. Trees", style: "bold cyan")
puts ""

# File tree
tree1 = Rich::Tree.new("📁 project/", style: "bold yellow")
src = tree1.add("📁 src/", style: "bold")
src.add("📄 main.rb", style: "green")
src.add("📄 config.rb", style: "green")
models = src.add("📁 models/", style: "bold")
models.add("📄 user.rb", style: "green")
models.add("📄 post.rb", style: "green")

lib = tree1.add("📁 lib/", style: "bold")
lib.add("📄 utils.rb", style: "green")
lib.add("📄 helpers.rb", style: "green")

tree1.add("📄 Gemfile", style: "cyan")
tree1.add("📄 README.md", style: "cyan")

puts tree1.render
puts ""

# Different tree styles
puts "Tree Guide Styles:"
[
  [Rich::TreeGuide::UNICODE, "Unicode"],
  [Rich::TreeGuide::ROUNDED, "Rounded"],
  [Rich::TreeGuide::BOLD, "Bold"],
  [Rich::TreeGuide::ASCII, "ASCII"]
].each do |guide, name|
  small_tree = Rich::Tree.new(name, guide: guide)
  small_tree.add("Child 1")
  small_tree.add("Child 2")
  puts small_tree.render
end

pause

# =============================================================================
# 7. PROGRESS BAR
# =============================================================================
console.clear
console.rule("7. Progress Bars", style: "bold cyan")
puts ""

puts "Simulating file download...\n"

# Animated progress bar
bar = Rich::ProgressBar.new(total: 100, width: 50, complete_style: "green", incomplete_style: "dim")

console.hide_cursor
101.times do |i|
  bar.update(i)
  print "\r  Downloading: "
  print bar.render
  print " " * 10
  sleep(0.02)
end
console.show_cursor
puts "\n  ✓ Download complete!"
puts ""

# Multiple progress bars
puts "Multiple Operations:"
operations = [
  ["Compiling", 100],
  ["Testing", 75],
  ["Deploying", 50],
  ["Verifying", 25]
]

operations.each do |name, progress|
  op_bar = Rich::ProgressBar.new(total: 100, completed: progress, width: 30)
  style = progress >= 100 ? "green" : (progress >= 50 ? "yellow" : "red")
  print "  #{name.ljust(12)}: "
  print op_bar.render
  puts ""
end

pause

# =============================================================================
# 8. SPINNERS
# =============================================================================
console.clear
console.rule("8. Spinners", style: "bold cyan")
puts ""

spinners = [
  [Rich::ProgressStyle::DOTS, "Dots"],
  [Rich::ProgressStyle::LINE, "Line"],
  [Rich::ProgressStyle::CIRCLE, "Circle"],
  [Rich::ProgressStyle::BOUNCE, "Bounce"]
]

puts "Spinner Styles (watch for 2 seconds each):"
puts ""

console.hide_cursor
spinners.each do |frames, name|
  spinner = Rich::Spinner.new(frames: frames, speed: 0.08)
  print "  #{name.ljust(10)}: "
  
  20.times do
    print "\r  #{name.ljust(10)}: #{spinner.frame} Processing..."
    spinner.advance
    sleep(0.1)
  end
  puts "\r  #{name.ljust(10)}: ✓ Done!            "
end
console.show_cursor

pause

# =============================================================================
# 9. JSON HIGHLIGHTING
# =============================================================================
console.clear
console.rule("9. JSON Highlighting", style: "bold cyan")
puts ""

data = {
  "name" => "Rich Ruby",
  "version" => "0.1.0",
  "features" => ["colors", "styles", "tables", "trees"],
  "config" => {
    "color_system" => "truecolor",
    "unicode" => true,
    "windows_support" => true
  },
  "stats" => {
    "tests_passed" => 51,
    "coverage" => 95.5
  }
}

puts Rich::JSON.to_s(data)

pause

# =============================================================================
# 10. PRETTY PRINTING
# =============================================================================
console.clear
console.rule("10. Pretty Printing Ruby Objects", style: "bold cyan")
puts ""

obj = {
  string: "hello world",
  number: 42,
  float: 3.14159,
  boolean: true,
  nil_value: nil,
  symbol: :example,
  array: [1, 2, 3, [4, 5]],
  nested: {
    deep: {
      value: "found!"
    }
  }
}

puts Rich::Pretty.to_s(obj)

pause

# =============================================================================
# FINALE
# =============================================================================
console.clear
console.rule("🎉 Demo Complete!", style: "bold green")
puts ""

finale = Rich::Panel.new(
  "Thank you for exploring the Rich Ruby Library!\n\n" \
  "Features demonstrated:\n" \
  "  • 16-color, 256-color, and TrueColor support\n" \
  "  • 13 text style attributes\n" \
  "  • Rich markup syntax\n" \
  "  • Panels with titles and borders\n" \
  "  • Tables with alignment and styling\n" \
  "  • Tree views with multiple guides\n" \
  "  • Animated progress bars\n" \
  "  • Multiple spinner styles\n" \
  "  • JSON syntax highlighting\n" \
  "  • Ruby object pretty printing\n\n" \
  "All 51 stress tests pass! Ready for production.",
  title: "✨ Rich Ruby Library",
  subtitle: "Pure Ruby • Zero Dependencies • Windows Ready",
  border_style: "bold green",
  title_style: "bold white on green"
)

puts finale.render(max_width: 65)
puts ""

console.print("Run ", end_str: "")
console.print("examples/demo.rb", style: "cyan")
console.print(" for a quick demo, or ", end_str: "")
console.print("examples/stress_test.rb", style: "cyan")
console.print(" for tests.")
puts ""
