# frozen_string_literal: true

# Comprehensive demo of Rich library features

require_relative "../lib/rich"

console = Rich::Console.new

# Title
console.rule("Rich Library Demo", style: "bold magenta")
puts ""

# 1. Colors and Styles
puts "1. Colors and Styles"
puts "=" * 40
console.print("Normal text")
console.print("Bold text", style: "bold")
console.print("Italic text", style: "italic")
console.print("Underlined text", style: "underline")
console.print("Red text", style: "red")
console.print("Green on yellow", style: "green on yellow")
console.print("Bold blue italic", style: "bold blue italic")
puts ""

# 2. Text with Spans
puts "2. Text with Style Spans"
puts "=" * 40
text = Rich::Text.new("Hello ")
text.append("World", style: "bold red")
text.append("! This is ")
text.append("Rich", style: "italic magenta")
text.append(" for Ruby.")
puts text.render + "\n"

# 3. Markup
puts "3. Markup Parsing"
puts "=" * 40
markup = Rich::Markup.render("[bold]Bold[/bold] and [italic red]italic red[/italic red] text")
puts markup + "\n"

# 4. Panel
puts "4. Panel Component"
puts "=" * 40
panel = Rich::Panel.new(
  "This is content inside a panel.\nIt can have multiple lines.",
  title: "My Panel",
  subtitle: "Subtitle here",
  border_style: "cyan",
  title_style: "bold white"
)
puts panel.render(max_width: 50)
puts ""

# 5. Table
puts "5. Table Component"
puts "=" * 40
table = Rich::Table.new(
  title: "User Data",
  show_header: true,
  border_style: "blue"
)
table.add_column("Name", header_style: "bold")
table.add_column("Age", justify: :right)
table.add_column("City", header_style: "bold green")

table.add_row("Alice", "30", "New York")
table.add_row("Bob", "25", "San Francisco")
table.add_row("Charlie", "35", "London")
table.add_row("Diana", "28", "Tokyo")

puts table.render(max_width: 60)
puts ""

# 6. Box Styles
puts "6. Different Box Styles"
puts "=" * 40

[Rich::Box::ASCII, Rich::Box::SQUARE, Rich::Box::ROUNDED, Rich::Box::HEAVY, Rich::Box::DOUBLE].each do |box_style|
  small_panel = Rich::Panel.new(
    "Content",
    title: box_style.class == Class ? box_style.name : "Box",
    box: box_style,
    expand: false,
    padding: 0
  )
  puts small_panel.render(max_width: 30)
end
puts ""

# 7. Color System Info
puts "7. System Information"
puts "=" * 40
info_table = Rich::Table.new(show_header: false, box: Rich::Box::SIMPLE)
info_table.add_column("Property", style: "cyan")
info_table.add_column("Value", style: "yellow")
info_table.add_row("Color System", console.color_system.to_s)
info_table.add_row("Terminal", console.terminal? ? "Yes" : "No")
info_table.add_row("Width", console.width.to_s)
info_table.add_row("Height", console.height.to_s)
info_table.add_row("Ruby Version", RUBY_VERSION)
info_table.add_row("Platform", RUBY_PLATFORM)

puts info_table.render(max_width: 50)
puts ""

console.rule("Demo Complete!", style: "bold green")
