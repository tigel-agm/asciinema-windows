# frozen_string_literal: true

require_relative "test_helper"

class TestConsole < Minitest::Test
  include TestHelper

  def test_creation
    console = Rich::Console.new
    refute_nil console
  end

  def test_width
    console = Rich::Console.new(width: 100)
    assert_equal 100, console.width
  end

  def test_height
    console = Rich::Console.new(height: 50)
    assert_equal 50, console.height
  end

  def test_size
    console = Rich::Console.new(width: 100, height: 50)
    size = console.size
    assert_equal 2, size.length
    assert_equal 100, size[0]
    assert_equal 50, size[1]
  end

  def test_color_system
    console = Rich::Console.new
    assert Rich::ColorSystem::ALL.include?(console.color_system)
  end

  def test_is_terminal_auto
    console = Rich::Console.new
    # Can be true or false depending on environment
    assert [true, false].include?(console.is_terminal?)
  end

  def test_is_terminal_forced
    console = Rich::Console.new(force_terminal: true)
    assert console.is_terminal?
  end

  def test_print
    console = Rich::Console.new(force_terminal: true)
    capture_output do
      console.print("Hello", style: "bold")
    end
  end

  def test_rule
    console = Rich::Console.new(force_terminal: true)
    capture_output do
      console.rule("Title", style: "bold")
    end
  end
end

class TestConsoleOptions < Minitest::Test
  def test_creation
    options = Rich::ConsoleOptions.new
    refute_nil options
  end

  def test_max_width
    options = Rich::ConsoleOptions.new(max_width: 80)
    assert_equal 80, options.max_width
  end

  def test_update
    options = Rich::ConsoleOptions.new(max_width: 80)
    updated = options.update(max_width: 120)
    assert_equal 120, updated.max_width
    assert_equal 80, options.max_width  # Original unchanged
  end
end

class TestBox < Minitest::Test
  def test_ascii_box
    box = Rich::Box::ASCII
    refute_nil box
    refute box.top_left.empty?
  end

  def test_square_box
    box = Rich::Box::SQUARE
    refute_nil box
  end

  def test_rounded_box
    box = Rich::Box::ROUNDED
    refute_nil box
  end

  def test_heavy_box
    box = Rich::Box::HEAVY
    refute_nil box
  end

  def test_double_box
    box = Rich::Box::DOUBLE
    refute_nil box
  end

  def test_box_top
    box = Rich::Box::ROUNDED
    top = box.top(10)
    assert_equal 10, Rich::Cells.cell_len(top)
  end

  def test_box_bottom
    box = Rich::Box::ROUNDED
    bottom = box.bottom(10)
    assert_equal 10, Rich::Cells.cell_len(bottom)
  end

  def test_box_row
    box = Rich::Box::ROUNDED
    row = box.row(["a", "b", "c"], [3, 3, 3])
    refute row.empty?
  end
end

class TestRichModule < Minitest::Test
  def test_get_console
    console = Rich.get_console
    refute_nil console
    assert console.is_a?(Rich::Console)
  end

  def test_reconfigure
    Rich.reconfigure(force_terminal: true)
    console = Rich.get_console
    refute_nil console
  end
end

# Windows-specific tests
if Gem.win_platform?
  class TestWin32Console < Minitest::Test
    def test_stdout_handle
      handle = Rich::Win32Console.stdout_handle
      refute_nil handle
    end

    def test_supports_ansi
      result = Rich::Win32Console.supports_ansi?
      assert [true, false].include?(result)
    end

    def test_get_size
      size = Rich::Win32Console.get_size
      assert size.nil? || (size.is_a?(Array) && size.length == 2)
    end

    def test_get_cursor_position
      pos = Rich::Win32Console.get_cursor_position
      # May return nil in some environments
      assert pos.nil? || (pos.is_a?(Array) && pos.length == 2)
    end
  end
end
