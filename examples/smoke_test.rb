# frozen_string_literal: true

# Smoke test for Rich library

require_relative "../lib/rich"

puts "1. Testing library load..."
puts "   Rich library loaded successfully!"

puts "\n2. Testing Console..."
console = Rich::Console.new
puts "   Color system: #{console.color_system}"
puts "   Terminal size: #{console.width}x#{console.height}"
puts "   Is terminal: #{console.terminal?}"

puts "\n3. Testing Color parsing..."
red = Rich::Color.parse("red")
puts "   Parsed 'red': #{red.inspect}"

hex = Rich::Color.parse("#ff5500")
puts "   Parsed '#ff5500': #{hex.inspect}"

puts "\n4. Testing Style parsing..."
style = Rich::Style.parse("bold red on white")
puts "   Parsed 'bold red on white': #{style.inspect}"

puts "\n5. Testing ColorTriplet..."
triplet = Rich::ColorTriplet.new(255, 128, 0)
puts "   Triplet: #{triplet.hex} / #{triplet.rgb}"

puts "\n6. Testing Cells width..."
puts "   Width of 'Hello': #{Rich::Cells.cell_len('Hello')}"
puts "   Width of '你好': #{Rich::Cells.cell_len('你好')}"

puts "\n7. Testing basic output..."
console.print("Hello from Rich!", style: "bold green")

puts "\n8. Testing markup..."
console.print_markup("[bold]Bold[/bold] and [red]Red[/red] text")

puts "\n✓ Smoke test complete!"
