# frozen_string_literal: true

require_relative "test_helper"

class TestStyle < Minitest::Test
  include TestHelper

  def test_parse_simple_color
    style = Rich::Style.parse("red")
    refute_nil style.color
    assert_equal "red", style.color.name
  end

  def test_parse_bold
    style = Rich::Style.parse("bold")
    assert style.bold?
  end

  def test_parse_italic
    style = Rich::Style.parse("italic")
    assert style.italic?
  end

  def test_parse_underline
    style = Rich::Style.parse("underline")
    assert style.underline?
  end

  def test_parse_combined
    style = Rich::Style.parse("bold red on blue")
    assert style.bold?
    assert_equal "red", style.color.name
    assert_equal "blue", style.bgcolor.name
  end

  def test_parse_negation
    style = Rich::Style.parse("not bold")
    assert_equal false, style.bold
  end

  def test_style_combination
    s1 = Rich::Style.parse("bold red")
    s2 = Rich::Style.parse("italic blue")
    combined = s1 + s2
    assert combined.bold?
    assert combined.italic?
    assert_equal "blue", combined.color.name
  end

  def test_style_combination_preserves_first
    s1 = Rich::Style.parse("red")
    s2 = Rich::Style.parse("bold")
    combined = s1 + s2
    assert combined.bold?
    assert_equal "red", combined.color.name
  end

  def test_render_produces_ansi
    style = Rich::Style.parse("bold red")
    rendered = style.render
    assert_has_ansi(rendered)
    assert_includes rendered, "1"  # Bold
    assert_includes rendered, "31" # Red
  end

  def test_null_style
    style = Rich::Style.null
    assert style.blank?
  end

  def test_blank_detection
    style = Rich::Style.new
    assert style.blank?

    style_with_color = Rich::Style.parse("red")
    refute style_with_color.blank?
  end

  def test_style_to_s
    style = Rich::Style.parse("bold red")
    str = style.to_s
    assert_includes str, "bold"
    assert_includes str, "red"
  end

  def test_style_equality
    s1 = Rich::Style.parse("bold red")
    s2 = Rich::Style.parse("bold red")
    assert_equal s1, s2
  end

  def test_all_attributes
    attrs = %i[bold dim italic underline blink reverse conceal strike]
    attrs.each do |attr|
      style = Rich::Style.new(**{ attr => true })
      assert style.send("#{attr}?"), "Expected #{attr} to be true"
    end
  end

  def test_style_with_link
    style = Rich::Style.new(link: "https://example.com")
    assert_equal "https://example.com", style.link
  end

  def test_without_color
    style = Rich::Style.parse("bold red on blue")
    plain = style.without_color
    assert plain.bold?
    assert_nil plain.color
    assert_nil plain.bgcolor
  end
end
