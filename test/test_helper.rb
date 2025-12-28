# frozen_string_literal: true

# Suppress environment warnings (like io-nonblock extensions)
$VERBOSE = nil

# Test helper for Rich library tests
# Sets up the test environment and provides common utilities

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rich"
require "minitest/autorun"

# Test utilities
module TestHelper
  # Capture stdout during block execution
  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  # Strip ANSI codes from string for comparison
  def strip_ansi(str)
    Rich::Control.strip_ansi(str)
  end

  # Assert that string contains ANSI escape codes
  def assert_has_ansi(str, msg = nil)
    assert_match(/\e\[[\d;]*m/, str, msg || "Expected string to contain ANSI codes")
  end

  # Assert that string does not contain ANSI escape codes
  def refute_has_ansi(str, msg = nil)
    refute_match(/\e\[[\d;]*m/, str, msg || "Expected string to not contain ANSI codes")
  end
end
