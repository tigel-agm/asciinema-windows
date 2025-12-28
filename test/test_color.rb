# frozen_string_literal: true

require_relative "test_helper"

class TestColor < Minitest::Test
  include TestHelper

  def test_parse_named_color
    color = Rich::Color.parse("red")
    assert_equal "red", color.name
    assert_equal Rich::ColorType::STANDARD, color.type
    assert_equal 1, color.number
  end

  def test_parse_bright_color
    color = Rich::Color.parse("bright_blue")
    assert_equal "bright_blue", color.name
    assert_equal 12, color.number
  end

  def test_parse_hex_color
    color = Rich::Color.parse("#ff5500")
    assert_equal Rich::ColorType::TRUECOLOR, color.type
    refute_nil color.triplet
    assert_equal 255, color.triplet.red
    assert_equal 85, color.triplet.green
    assert_equal 0, color.triplet.blue
  end

  def test_parse_rgb_color
    color = Rich::Color.parse("rgb(100,150,200)")
    assert_equal Rich::ColorType::TRUECOLOR, color.type
    assert_equal 100, color.triplet.red
    assert_equal 150, color.triplet.green
    assert_equal 200, color.triplet.blue
  end

  def test_parse_color_number
    color = Rich::Color.parse("color(42)")
    assert_equal Rich::ColorType::EIGHT_BIT, color.type
    assert_equal 42, color.number
  end

  def test_color_downgrade_to_256
    color = Rich::Color.from_triplet(Rich::ColorTriplet.new(128, 64, 192))
    downgraded = color.downgrade(Rich::ColorSystem::EIGHT_BIT)
    assert_equal Rich::ColorType::EIGHT_BIT, downgraded.type
    assert downgraded.number.between?(0, 255)
  end

  def test_color_downgrade_to_16
    color = Rich::Color.from_triplet(Rich::ColorTriplet.new(255, 0, 0))
    downgraded = color.downgrade(Rich::ColorSystem::STANDARD)
    assert_equal Rich::ColorType::STANDARD, downgraded.type
    assert downgraded.number.between?(0, 15)
  end

  def test_ansi_codes_foreground
    color = Rich::Color.parse("red")
    codes = color.ansi_codes(foreground: true)
    assert_includes codes, "31"
  end

  def test_ansi_codes_background
    color = Rich::Color.parse("blue")
    codes = color.ansi_codes(foreground: false)
    assert_includes codes, "44"
  end

  def test_default_color
    color = Rich::Color.default
    assert_equal "default", color.name
    assert_equal Rich::ColorType::DEFAULT, color.type
  end

  def test_color_equality
    c1 = Rich::Color.parse("red")
    c2 = Rich::Color.parse("red")
    assert_equal c1, c2
  end

  def test_invalid_color_raises
    assert_raises(Rich::ColorParseError) do
      Rich::Color.parse("not_a_color_name")
    end
  end
end

class TestColorTriplet < Minitest::Test
  def test_creation
    triplet = Rich::ColorTriplet.new(100, 150, 200)
    assert_equal 100, triplet.red
    assert_equal 150, triplet.green
    assert_equal 200, triplet.blue
  end

  def test_hex_conversion
    triplet = Rich::ColorTriplet.new(255, 128, 0)
    assert_equal "ff8000", triplet.hex
  end

  def test_from_hex
    triplet = Rich::ColorTriplet.from_hex("#ff5500")
    assert_equal 255, triplet.red
    assert_equal 85, triplet.green
    assert_equal 0, triplet.blue
  end

  def test_from_hsl
    triplet = Rich::ColorTriplet.from_hsl(0, 100, 50)
    assert_equal 255, triplet.red
    assert triplet.green < 10
    assert triplet.blue < 10
  end

  def test_normalized
    triplet = Rich::ColorTriplet.new(255, 128, 0)
    norm = triplet.normalized
    assert_in_delta 1.0, norm[0], 0.01
    assert_in_delta 0.5, norm[1], 0.01
    assert_in_delta 0.0, norm[2], 0.01
  end

  def test_equality
    t1 = Rich::ColorTriplet.new(100, 100, 100)
    t2 = Rich::ColorTriplet.new(100, 100, 100)
    assert_equal t1, t2
  end
end
