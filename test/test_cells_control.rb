# frozen_string_literal: true

require_relative "test_helper"

class TestCells < Minitest::Test
  def test_ascii_width
    assert_equal 5, Rich::Cells.cell_len("hello")
  end

  def test_empty_string
    assert_equal 0, Rich::Cells.cell_len("")
  end

  def test_cjk_width
    # CJK characters are typically 2 cells wide
    width = Rich::Cells.cell_len("中")
    assert_equal 2, width
  end

  def test_mixed_width
    # "Hi" (2) + Chinese char (2) = 4
    width = Rich::Cells.cell_len("Hi中")
    assert_equal 4, width
  end

  def test_tab_width
    assert_equal 1, Rich::Cells.cell_len("\t")
  end

  def test_newline_width
    assert_equal 1, Rich::Cells.cell_len("\n")
  end

  def test_char_width_ascii
    assert_equal 1, Rich::Cells.char_width("a")
  end

  def test_char_width_cjk
    assert_equal 2, Rich::Cells.char_width("中")
  end

  def test_char_width_nil
    assert_equal 0, Rich::Cells.char_width(nil)
  end

  def test_char_width_empty
    assert_equal 0, Rich::Cells.char_width("")
  end

  def test_zero_width_detection
    # Combining accent should be zero width
    combining = "\u0301"  # Combining acute accent
    assert Rich::Cells.zero_width?(combining)
  end

  def test_wide_detection
    assert Rich::Cells.wide?("中")
    refute Rich::Cells.wide?("a")
  end

  def test_cached_cell_len
    text = "test string"
    # Call twice to test caching
    len1 = Rich::Cells.cached_cell_len(text)
    len2 = Rich::Cells.cached_cell_len(text)
    assert_equal len1, len2
    assert_equal 11, len1
  end
end

class TestControl < Minitest::Test
  include TestHelper

  def test_clear_screen
    result = Rich::Control.clear_screen
    assert_includes result, "\e[2J"
  end

  def test_cursor_up
    result = Rich::Control.cursor_up(5)
    assert_includes result, "\e[5A"
  end

  def test_cursor_down
    result = Rich::Control.cursor_down(3)
    assert_includes result, "\e[3B"
  end

  def test_cursor_forward
    result = Rich::Control.cursor_forward(10)
    assert_includes result, "\e[10C"
  end

  def test_cursor_backward
    result = Rich::Control.cursor_backward(2)
    assert_includes result, "\e[2D"
  end

  def test_cursor_move_to
    result = Rich::Control.cursor_move_to(10, 20)
    assert_includes result, "\e[10;20H"
  end

  def test_hide_cursor
    result = Rich::Control.hide_cursor
    assert_includes result, "\e[?25l"
  end

  def test_show_cursor
    result = Rich::Control.show_cursor
    assert_includes result, "\e[?25h"
  end

  def test_set_title
    result = Rich::Control.set_title("My Title")
    assert_includes result, "My Title"
    assert_includes result, "\e]2;"
  end

  def test_hyperlink
    result = Rich::Control.hyperlink("https://example.com", "Click here")
    assert_includes result, "Click here"
    assert_includes result, "https://example.com"
  end

  def test_strip_ansi
    styled = "\e[1;31mHello\e[0m World"
    stripped = Rich::Control.strip_ansi(styled)
    assert_equal "Hello World", stripped
  end

  def test_strip_ansi_plain
    plain = "Hello World"
    stripped = Rich::Control.strip_ansi(plain)
    assert_equal plain, stripped
  end
end
