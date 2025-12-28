# frozen_string_literal: true

# Rich - A Ruby library for rich text and beautiful formatting in the terminal.
#
# Rich provides a simple API for adding color and style to terminal output.
# It supports true color (24-bit), 256-color, and 16-color terminals with
# automatic fallback. Full Windows Console API support included.
#
# @example Basic usage
#   require 'rich'
#
#   Rich.print("[bold red]Hello[/] [green]World[/]!")
#   Rich.print("[italic blue on white]Styled text[/]")
#
# @example Using the Console directly
#   console = Rich::Console.new
#   console.print("Hello", style: "bold magenta")
#
# @example Tables
#   table = Rich::Table.new(title: "Users")
#   table.add_column("Name")
#   table.add_column("Age")
#   table.add_row("Alice", "30")
#   Rich.print(table)

require_relative "rich/version"
require_relative "rich/color_triplet"
require_relative "rich/_palettes"
require_relative "rich/color"
require_relative "rich/terminal_theme"
require_relative "rich/style"
require_relative "rich/cells"
require_relative "rich/control"
require_relative "rich/segment"
require_relative "rich/text"
require_relative "rich/markup"
require_relative "rich/box"
require_relative "rich/panel"
require_relative "rich/table"
require_relative "rich/progress"
require_relative "rich/tree"
require_relative "rich/json"
require_relative "rich/layout"
require_relative "rich/syntax"
require_relative "rich/markdown"
require_relative "rich/win32_console" if Gem.win_platform?

module Rich
  class << self
    # Global console instance
    # @return [Console, nil]
    attr_accessor :console

    # Get or create the global console
    # @return [Console]
    def get_console
      @console ||= Console.new
    end

    # Reconfigure the global console
    # @param kwargs [Hash] Console options
    # @return [void]
    def reconfigure(**kwargs)
      @console = Console.new(**kwargs)
    end

    # Print to the console with markup support
    # @param objects [Array] Objects to print
    # @param sep [String] Separator between objects
    # @param end_str [String] End of line string
    # @param style [String, Style, nil] Style to apply
    # @param highlight [Boolean] Enable highlighting
    # @return [void]
    def print(*objects, sep: " ", end_str: "\n", style: nil, highlight: true)
      get_console.print(*objects, sep: sep, end_str: end_str, style: style, highlight: highlight)
    end

    # Print JSON with syntax highlighting
    # @param json [String, nil] JSON string
    # @param data [Object] Object to convert to JSON
    # @param indent [Integer] Indentation level
    # @return [void]
    def print_json(json = nil, data: nil, indent: 2)
      get_console.print_json(json, data: data, indent: indent)
    end

    # Inspect an object and print its details
    # @param obj [Object] Object to inspect
    # @param title [String, nil] Title
    # @param methods [Boolean] Show methods
    # @param docs [Boolean] Show documentation
    # @return [void]
    def inspect(obj, title: nil, methods: false, docs: true)
      get_console.inspect(obj, title: title, methods: methods, docs: docs)
    end

    # Create a rule/separator line
    # @param title [String] Title text
    # @param style [String] Style for the rule
    # @return [void]
    def rule(title = "", style: "rule.line")
      get_console.rule(title, style: style)
    end
  end
end

# Auto-require Console after base modules are loaded
require_relative "rich/console"
