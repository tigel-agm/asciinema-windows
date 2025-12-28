# frozen_string_literal: true

# Quick visual demo - no interaction needed

require_relative "../lib/rich"

console = Rich::Console.new

puts ""
console.rule("🎨 Rich Ruby - Quick Visual Demo", style: "bold magenta")
puts ""

# =============================================================================
# COLORS & STYLES
# =============================================================================
puts "▸ Color & Style Examples:"
puts ""
console.print("  Normal text")
console.print("  Bold text", style: "bold")
console.print("  Italic text", style: "italic")
console.print("  Underlined text", style: "underline")
console.print("  Red text", style: "red")
console.print("  Green on black", style: "green on black")
console.print("  Bold blue", style: "bold blue")
console.print("  Bright magenta italic", style: "bright_magenta italic")
puts ""

# Color gradient
print "  Gradient: "
40.times do |i|
  r = (255 * i / 40.0).to_i
  g = (128).to_i
  b = (255 * (40 - i) / 40.0).to_i
  style = Rich::Style.new(bgcolor: Rich::Color.from_triplet(Rich::ColorTriplet.new(r, g, b)))
  console.write(style.render + " " + "\e[0m")
end
puts ""
puts ""

# =============================================================================
# PANEL
# =============================================================================
puts "▸ Panel Example:"
puts ""
panel = Rich::Panel.new(
  "Panels are great for highlighting content!\nThey support titles, subtitles, and styles.",
  title: "📦 My Panel",
  subtitle: "Rich Ruby Library",
  border_style: "cyan",
  title_style: "bold white"
)
puts panel.render(max_width: 55)
puts ""

# =============================================================================
# TABLE
# =============================================================================
puts "▸ Table Example:"
puts ""
table = Rich::Table.new(title: "📊 System Stats", border_style: "green")
table.add_column("Metric", header_style: "bold cyan")
table.add_column("Value", justify: :right, header_style: "bold cyan")
table.add_column("Status", justify: :center, header_style: "bold cyan")

table.add_row("CPU Usage", "45%", "🟢 Normal")
table.add_row("Memory", "2.4 GB", "🟢 Normal")
table.add_row("Disk I/O", "120 MB/s", "🟡 High")
table.add_row("Network", "50 Mbps", "🟢 Normal")

puts table.render(max_width: 55)
puts ""

# =============================================================================
# TREE
# =============================================================================
puts "▸ Tree Example:"
puts ""
tree = Rich::Tree.new("📁 my_project/", style: "bold yellow")
src = tree.add("📁 src/", style: "bold")
src.add("📄 main.rb", style: "green")
src.add("📄 config.rb", style: "green")
models = src.add("📁 models/", style: "bold")
models.add("📄 user.rb", style: "green")
models.add("📄 post.rb", style: "green")
tree.add("📄 Gemfile", style: "cyan")
tree.add("📄 README.md", style: "cyan")

puts tree.render
puts ""

# =============================================================================
# PROGRESS BARS
# =============================================================================
puts "▸ Progress Bar Examples:"
puts ""

[0, 25, 50, 75, 100].each do |pct|
  bar = Rich::ProgressBar.new(total: 100, completed: pct, width: 30, complete_style: "green", incomplete_style: "dim")
  print "  #{pct.to_s.rjust(3)}%: "
  puts bar.render
end
puts ""

# =============================================================================
# SPINNERS
# =============================================================================
puts "▸ Spinner Styles:"
puts ""
spinners = [
  [Rich::ProgressStyle::DOTS, "Dots   "],
  [Rich::ProgressStyle::LINE, "Line   "],
  [Rich::ProgressStyle::CIRCLE, "Circle "],
  [Rich::ProgressStyle::BOUNCE, "Bounce "]
]

spinners.each do |frames, name|
  print "  #{name}: "
  frames.each { |f| print "#{f} " }
  puts ""
end
puts ""

# =============================================================================
# JSON
# =============================================================================
puts "▸ JSON Highlighting:"
puts ""
data = {
  "name" => "Rich",
  "version" => "0.1.0",
  "features" => ["colors", "tables", "trees"],
  "windows" => true
}
puts Rich::JSON.to_s(data)
puts ""

# =============================================================================
# FINALE
# =============================================================================
console.rule("✅ Demo Complete!", style: "bold green")
puts ""
console.print("Run ", end_str: "")
console.print("examples/showcase.rb", style: "bold cyan")
console.print(" for the interactive version with animations!")
puts ""
