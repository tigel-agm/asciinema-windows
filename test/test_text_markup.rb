# frozen_string_literal: true

require_relative "test_helper"

class TestText < Minitest::Test
  include TestHelper

  def test_creation
    text = Rich::Text.new("Hello World")
    assert_equal "Hello World", text.plain
  end

  def test_with_style
    text = Rich::Text.new("Hello", style: "bold red")
    refute_nil text.style
  end

  def test_stylize
    text = Rich::Text.new("Hello World")
    text.stylize("bold", 0, 5)
    segments = text.to_segments
    assert segments.length >= 1
  end

  def test_stylize_range
    text = Rich::Text.new("Hello World")
    text.stylize("red", 6, 11)
    segments = text.to_segments
    refute segments.empty?
  end

  def test_append
    text = Rich::Text.new("Hello")
    text.append(" World", style: "bold")
    assert_equal "Hello World", text.plain
  end

  def test_length
    text = Rich::Text.new("Hello")
    assert_equal 5, text.length
  end

  def test_empty
    empty = Rich::Text.new("")
    assert empty.empty?

    text = Rich::Text.new("x")
    refute text.empty?
  end

  def test_to_segments
    text = Rich::Text.new("Hello World")
    segments = text.to_segments
    assert segments.is_a?(Array)
    refute segments.empty?
  end

  def test_wrap
    text = Rich::Text.new("This is a longer text that should wrap")
    wrapped = text.wrap(10)
    assert wrapped.is_a?(Array)
    assert wrapped.length > 1
  end

  def test_wrap_preserves_content
    original = "Hello World Test"
    text = Rich::Text.new(original)
    wrapped = text.wrap(100)
    content = wrapped.map(&:plain).join
    assert_equal original, content
  end

  def test_split
    text = Rich::Text.new("Hello\nWorld\nTest")
    lines = text.split
    assert_equal 3, lines.length
  end

  def test_highlight_words
    text = Rich::Text.new("Hello World Hello")
    text.highlight_words(["Hello"], style: "bold")
    segments = text.to_segments
    refute segments.empty?
  end

  def test_highlight_regex
    text = Rich::Text.new("Test 123 Test 456")
    text.highlight_regex(/\d+/, style: "cyan")
    segments = text.to_segments
    refute segments.empty?
  end

  def test_cell_length
    text = Rich::Text.new("Hello")
    assert_equal 5, text.cell_length
  end

  def test_slice
    text = Rich::Text.new("Hello World")
    sliced = text.slice(0, 5)
    assert_equal "Hello", sliced.plain
  end

  def test_copy
    text = Rich::Text.new("Hello", style: "bold")
    copy = text.copy
    assert_equal text.plain, copy.plain
    refute_same text, copy
  end
end

class TestMarkup < Minitest::Test
  include TestHelper

  def test_parse_simple
    text = Rich::Markup.parse("[bold]Hello[/bold]")
    assert_equal "Hello", text.plain
  end

  def test_parse_nested
    text = Rich::Markup.parse("[bold][red]Hello[/red][/bold]")
    assert_equal "Hello", text.plain
  end

  def test_parse_shorthand_close
    text = Rich::Markup.parse("[bold]Hello[/]")
    assert_equal "Hello", text.plain
  end

  def test_parse_with_text
    text = Rich::Markup.parse("Before [bold]middle[/bold] after")
    assert_equal "Before middle after", text.plain
  end

  def test_escape
    escaped = Rich::Markup.escape("[bold]Not bold[/bold]")
    assert_includes escaped, "\\["
  end

  def test_validate_valid
    errors = Rich::Markup.validate("[bold]Hello[/bold]")
    assert_empty errors
  end

  def test_validate_unclosed
    errors = Rich::Markup.validate("[bold]Hello")
    refute_empty errors
  end

  def test_validate_unmatched
    errors = Rich::Markup.validate("[bold]Hello[/italic]")
    refute_empty errors
  end

  def test_render
    rendered = Rich::Markup.render("[bold red]Hello[/]")
    assert_has_ansi(rendered)
    assert_includes strip_ansi(rendered), "Hello"
  end

  def test_complex_markup
    markup = "[bold]Name:[/] [cyan]Alice[/] | [green]Status:[/] Active"
    text = Rich::Markup.parse(markup)
    assert_equal "Name: Alice | Status: Active", text.plain
  end
end
