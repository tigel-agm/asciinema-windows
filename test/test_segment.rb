# frozen_string_literal: true

require_relative "test_helper"

class TestSegment < Minitest::Test
  include TestHelper

  def test_creation
    segment = Rich::Segment.new("Hello")
    assert_equal "Hello", segment.text
    assert_nil segment.style
    refute segment.control?
  end

  def test_with_style
    style = Rich::Style.parse("bold red")
    segment = Rich::Segment.new("Hello", style: style)
    assert_equal style, segment.style
  end

  def test_cell_length
    segment = Rich::Segment.new("Hello")
    assert_equal 5, segment.cell_length
  end

  def test_empty_detection
    empty = Rich::Segment.new("")
    assert empty.empty?

    filled = Rich::Segment.new("x")
    refute filled.empty?
  end

  def test_present_detection
    segment = Rich::Segment.new("Hello")
    assert segment.present?

    empty = Rich::Segment.new("")
    refute empty.present?
  end

  def test_control_segment
    control = Rich::Segment.control([[Rich::Control::ControlType::CLEAR]])
    assert control.control?
    assert_equal 0, control.cell_length
  end

  def test_split_cells
    segment = Rich::Segment.new("Hello World")
    before, after = segment.split_cells(5)
    assert_equal "Hello", before.text
    assert_equal " World", after.text
  end

  def test_split_cells_at_zero
    segment = Rich::Segment.new("Hello")
    before, after = segment.split_cells(0)
    assert_equal "", before.text
    assert_equal "Hello", after.text
  end

  def test_split_cells_at_end
    segment = Rich::Segment.new("Hello")
    before, after = segment.split_cells(10)
    assert_equal "Hello", before.text
    assert_equal "", after.text
  end

  def test_line_segment
    line = Rich::Segment.line
    assert_equal "\n", line.text
  end

  def test_blank_segment
    blank = Rich::Segment.blank(5)
    assert_equal "     ", blank.text
    assert_equal 5, blank.cell_length
  end

  def test_split_lines
    segments = [
      Rich::Segment.new("Line1\nLine2"),
      Rich::Segment.new("\nLine3")
    ]
    lines = Rich::Segment.split_lines(segments)
    assert_equal 3, lines.length
  end

  def test_simplify
    style = Rich::Style.parse("bold")
    segments = [
      Rich::Segment.new("a", style: style),
      Rich::Segment.new("b", style: style),
      Rich::Segment.new("c", style: style)
    ]
    simplified = Rich::Segment.simplify(segments)
    assert simplified.length < segments.length
    assert_equal "abc", simplified.map(&:text).join
  end

  def test_apply_style
    segments = [Rich::Segment.new("Hello")]
    style = Rich::Style.parse("bold")
    styled = Rich::Segment.apply_style(segments, style: style)
    assert_equal style, styled.first.style
  end

  def test_render
    style = Rich::Style.parse("bold red")
    segments = [Rich::Segment.new("Hello", style: style)]
    output = Rich::Segment.render(segments)
    assert_has_ansi(output)
    assert_includes strip_ansi(output), "Hello"
  end

  def test_equality
    s1 = Rich::Segment.new("Hello")
    s2 = Rich::Segment.new("Hello")
    assert_equal s1, s2
  end
end
