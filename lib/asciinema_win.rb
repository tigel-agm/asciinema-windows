# frozen_string_literal: true

# AsciinemaWin - Native Windows Terminal Recorder in Pure Ruby
#
# A zero-dependency terminal recording and playback system for Windows.
# Uses Ruby's built-in Fiddle for Win32 Console API access and integrates
# Rich-Ruby for terminal rendering. Compatible with asciinema's asciicast v2 format.
#
# @example Record a terminal session
#   AsciinemaWin.record("session.cast", title: "My Recording")
#
# @example Play back a recording
#   AsciinemaWin.play("session.cast", speed: 1.5)
#
# @example Get recording info
#   info = AsciinemaWin.info("session.cast")
#   puts "Duration: #{info[:duration]}s"

module AsciinemaWin
  # Base error class for all AsciinemaWin errors
  class Error < StandardError; end

  # Raised when recording fails
  class RecordingError < Error; end

  # Raised when playback fails
  class PlaybackError < Error; end

  # Raised when file format is invalid
  class FormatError < Error; end

  # Raised when platform is not supported
  class PlatformError < Error; end

  # Raised when export fails
  class ExportError < Error; end
end

require_relative "rich"
require_relative "asciinema_win/version"
require_relative "asciinema_win/screen_buffer"
require_relative "asciinema_win/asciicast"
require_relative "asciinema_win/recorder"
require_relative "asciinema_win/player"
require_relative "asciinema_win/themes"
require_relative "asciinema_win/ansi_parser"
require_relative "asciinema_win/output_organizer"
require_relative "asciinema_win/export"
require_relative "asciinema_win/cli"

module AsciinemaWin

  class << self
    # Record a terminal session to a file
    #
    # @param output_path [String] Path to save the recording
    # @param title [String, nil] Recording title
    # @param command [String, nil] Command to record (runs in subprocess)
    # @param idle_time_limit [Float] Maximum idle time between events
    # @param env_vars [Array<String>] Environment variables to capture
    # @yield [Recorder] Optional block for manual recording control
    # @return [void]
    # @raise [RecordingError] If recording fails
    # @raise [PlatformError] If not running on Windows
    #
    # @example Record interactively
    #   AsciinemaWin.record("session.cast", title: "Demo") do |rec|
    #     # Recording happens until block exits or user presses Ctrl+D
    #   end
    #
    # @example Record a command
    #   AsciinemaWin.record("session.cast", command: "dir /s")
    def record(output_path, title: nil, command: nil, idle_time_limit: 2.0, env_vars: %w[SHELL TERM], &block)
      ensure_windows!

      recorder = Recorder.new(
        title: title,
        command: command,
        idle_time_limit: idle_time_limit,
        env_vars: env_vars
      )

      recorder.record(output_path, &block)
    end

    # Play back a recording from a file
    #
    # @param input_path [String] Path to the recording file
    # @param speed [Float] Playback speed multiplier (1.0 = normal)
    # @param idle_time_limit [Float, nil] Cap idle time between frames
    # @param pause_on_markers [Boolean] Pause playback at markers
    # @return [void]
    # @raise [PlaybackError] If playback fails
    # @raise [FormatError] If file format is invalid
    #
    # @example Normal playback
    #   AsciinemaWin.play("session.cast")
    #
    # @example Fast playback
    #   AsciinemaWin.play("session.cast", speed: 2.0)
    def play(input_path, speed: 1.0, idle_time_limit: nil, pause_on_markers: false)
      player = Player.new(
        speed: speed,
        idle_time_limit: idle_time_limit,
        pause_on_markers: pause_on_markers
      )

      player.play(input_path)
    end

    # Output recording to stdout without timing (for piping)
    #
    # @param input_path [String] Path to the recording file
    # @return [void]
    # @raise [FormatError] If file format is invalid
    def cat(input_path)
      player = Player.new(speed: Float::INFINITY)
      player.play(input_path)
    end

    # Get metadata about a recording
    #
    # @param input_path [String] Path to the recording file
    # @return [Hash] Recording metadata including width, height, duration, title
    # @raise [FormatError] If file format is invalid
    #
    # @example
    #   info = AsciinemaWin.info("session.cast")
    #   puts "Size: #{info[:width]}x#{info[:height]}"
    #   puts "Duration: #{info[:duration]}s"
    def info(input_path)
      Asciicast::Reader.info(input_path)
    end

    # Run the CLI with the given arguments
    #
    # @param args [Array<String>] Command-line arguments
    # @return [Integer] Exit code
    def run(args = ARGV)
      CLI.run(args)
    end

    private

    # @raise [PlatformError] If not running on Windows
    # @return [void]
    def ensure_windows!
      return if Gem.win_platform?

      raise PlatformError, "AsciinemaWin requires Windows. Use the standard asciinema on other platforms."
    end
  end
end
