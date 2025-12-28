# frozen_string_literal: true

require_relative "style"
require_relative "segment"
require_relative "cells"

module Rich
  # Progress bar styles
  module ProgressStyle
    # Bar characters
    BAR_FILLED = "━"
    BAR_UNFILLED = "━"
    BAR_START = ""
    BAR_END = ""

    # Spinner frames
    DOTS = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze
    LINE = %w[| / - \\].freeze
    ARROW = %w[←↖↑↗→↘↓↙].freeze
    CIRCLE = %w[◐ ◓ ◑ ◒].freeze
    MOON = %w[🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘].freeze
    BOUNCE = %w[⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈].freeze
  end

  # A spinning animation indicator
  class Spinner
    # @return [Array<String>] Spinner frames
    attr_reader :frames

    # @return [Style, nil] Style
    attr_reader :style

    # @return [Float] Speed (seconds per frame)
    attr_reader :speed

    def initialize(frames: ProgressStyle::DOTS, style: nil, speed: 0.1)
      @frames = frames
      @style = style.is_a?(String) ? Style.parse(style) : style
      @speed = speed
      @frame_index = 0
      @last_update = Time.now
    end

    # Get current frame
    # @return [String]
    def frame
      @frames[@frame_index % @frames.length]
    end

    # Advance to next frame
    # @return [String] Current frame after advance
    def advance
      @frame_index = (@frame_index + 1) % @frames.length
      @last_update = Time.now
      frame
    end

    # Update if enough time has passed
    # @return [Boolean] True if frame changed
    def update
      if Time.now - @last_update >= @speed
        advance
        true
      else
        false
      end
    end

    # Get segment for current frame
    # @return [Segment]
    def to_segment
      Segment.new(frame, style: @style)
    end

    # Reset to first frame
    def reset
      @frame_index = 0
      @last_update = Time.now
    end
  end

  # A progress bar for tracking task completion
  class ProgressBar
    # @return [Integer] Total steps
    attr_reader :total

    # @return [Integer] Completed steps
    attr_reader :completed

    # @return [Integer] Width of the bar
    attr_reader :width

    # @return [Style, nil] Completed portion style
    attr_reader :complete_style

    # @return [Style, nil] Remaining portion style
    attr_reader :incomplete_style

    # @return [Style, nil] Finished style
    attr_reader :finished_style

    # @return [Boolean] Show percentage
    attr_reader :show_percentage

    # @return [Boolean] Pulse animation
    attr_reader :pulse

    # @return [String] Bar character (filled)
    attr_reader :bar_char

    # @return [String] Bar character (unfilled)
    attr_reader :unfilled_char

    def initialize(
      total: 100,
      completed: 0,
      width: 40,
      complete_style: "bar.complete",
      incomplete_style: "bar.back",
      finished_style: "bar.finished",
      show_percentage: true,
      pulse: false,
      bar_char: "━",
      unfilled_char: "━"
    )
      @total = [total, 1].max
      @completed = [completed, 0].max
      @width = width
      @complete_style = complete_style.is_a?(String) ? Style.parse(complete_style) : complete_style
      @incomplete_style = incomplete_style.is_a?(String) ? Style.parse(incomplete_style) : incomplete_style
      @finished_style = finished_style.is_a?(String) ? Style.parse(finished_style) : finished_style
      @show_percentage = show_percentage
      @pulse = pulse
      @bar_char = bar_char
      @unfilled_char = unfilled_char
      @start_time = nil
    end

    # @return [Float] Progress as fraction (0.0 to 1.0)
    def progress
      @completed.to_f / @total
    end

    # @return [Integer] Progress as percentage (0 to 100)
    def percentage
      (progress * 100).round
    end

    # @return [Boolean] True if complete
    def finished?
      @completed >= @total
    end

    # Update progress
    # @param advance [Integer] Steps to advance
    # @return [self]
    def advance(steps = 1)
      @start_time ||= Time.now
      @completed = [@completed + steps, @total].min
      self
    end

    # Set completed value directly
    # @param value [Integer] Completed steps
    # @return [self]
    def update(value)
      @start_time ||= Time.now
      @completed = [[value, 0].max, @total].min
      self
    end

    # Reset progress
    # @return [self]
    def reset
      @completed = 0
      @start_time = nil
      self
    end

    # Elapsed time since start
    # @return [Float, nil] Seconds elapsed
    def elapsed
      return nil unless @start_time

      Time.now - @start_time
    end

    # Estimated time remaining
    # @return [Float, nil] Seconds remaining
    def eta
      return nil unless @start_time && progress > 0

      elapsed_time = elapsed
      total_estimated = elapsed_time / progress
      total_estimated - elapsed_time
    end

    # Format time as string
    # @param seconds [Float] Seconds
    # @return [String] Formatted time
    def format_time(seconds)
      return "--:--" unless seconds

      mins = (seconds / 60).floor
      secs = (seconds % 60).floor

      if mins >= 60
        hours = (mins / 60).floor
        mins = mins % 60
        format("%d:%02d:%02d", hours, mins, secs)
      else
        format("%d:%02d", mins, secs)
      end
    end

    # Render progress bar to segments
    # @return [Array<Segment>]
    def to_segments
      segments = []

      filled_width = (progress * @width).round
      unfilled_width = @width - filled_width

      # Bar
      style = finished? ? @finished_style : @complete_style

      if filled_width > 0
        segments << Segment.new(@bar_char * filled_width, style: style)
      end

      if unfilled_width > 0
        segments << Segment.new(@unfilled_char * unfilled_width, style: @incomplete_style)
      end

      # Percentage
      if @show_percentage
        segments << Segment.new(" #{percentage}%")
      end

      segments
    end

    # Render to string with ANSI codes
    # @param color_system [Symbol] Color system
    # @return [String]
    def render(color_system: ColorSystem::TRUECOLOR)
      Segment.render(to_segments, color_system: color_system)
    end
  end

  # A task in progress tracking
  class ProgressTask
    # @return [String] Task description
    attr_reader :description

    # @return [Integer] Total steps
    attr_reader :total

    # @return [Integer] Completed steps
    attr_reader :completed

    # @return [Boolean] Task is finished
    attr_reader :finished

    # @return [Time] Start time
    attr_reader :start_time

    # @return [Time, nil] End time
    attr_reader :end_time

    def initialize(description:, total: 100)
      @description = description
      @total = total
      @completed = 0
      @finished = false
      @start_time = Time.now
      @end_time = nil
    end

    # Update progress
    # @param advance [Integer] Steps to advance
    def advance(steps = 1)
      @completed = [@completed + steps, @total].min
      finish if @completed >= @total
    end

    # Set completed directly
    # @param value [Integer] Completed value
    def update(value)
      @completed = [[value, 0].max, @total].min
      finish if @completed >= @total
    end

    # Mark as finished
    def finish
      @finished = true
      @end_time = Time.now
    end

    # @return [Float] Progress fraction
    def progress
      @completed.to_f / @total
    end

    # @return [Float, nil] Elapsed time
    def elapsed
      (@end_time || Time.now) - @start_time
    end
  end

  # Progress display for multiple tasks
  class Progress
    # Windows has slower console, so refresh less frequently
    DEFAULT_REFRESH = Gem.win_platform? ? 0.2 : 0.1

    # @return [Array<ProgressTask>] Tasks
    attr_reader :tasks

    # @return [Console] Console for output
    attr_reader :console

    # @return [Float] Refresh interval
    attr_reader :refresh_rate

    def initialize(console: nil, refresh_rate: DEFAULT_REFRESH, transient: true)
      @console = console || Console.new
      @refresh_rate = refresh_rate
      @transient = transient
      @tasks = []
      @started = false
      @finished = false
      @last_render = nil
    end

    # Add a new task
    # @param description [String] Task description
    # @param total [Integer] Total steps
    # @return [ProgressTask]
    def add_task(description, total: 100)
      task = ProgressTask.new(description: description, total: total)
      @tasks << task
      task
    end

    # Start progress display
    # @yield Block to execute with progress tracking
    # @return [void]
    def start
      @started = true
      @console.hide_cursor

      if block_given?
        begin
          yield self
        ensure
          stop
        end
      end
    end

    # Stop progress display
    # @return [void]
    def stop
      return unless @started

      @finished = true
      render_final
      @console.show_cursor
      @started = false
    end

    # Refresh display if needed
    # @return [void]
    def refresh
      return unless @started

      now = Time.now
      if @last_render.nil? || now - @last_render >= @refresh_rate
        render
        @last_render = now
      end
    end

    private

    def render
      # Clear previous output
      lines = @tasks.length
      @console.write("\e[#{lines}A\e[J") if @last_render

      @tasks.each do |task|
        render_task(task)
        @console.write("\n")
      end
    end

    def render_final
      return if @transient

      @tasks.each do |task|
        render_task(task)
        @console.write("\n")
      end
    end

    def render_task(task)
      bar = ProgressBar.new(
        total: task.total,
        completed: task.completed,
        width: 30,
        complete_style: "green",
        incomplete_style: "dim"
      )

      description = task.description.ljust(30)[0, 30]
      percentage = "#{(task.progress * 100).round}%".rjust(4)
      elapsed = format_time(task.elapsed)

      @console.write("#{description} ")
      @console.write_segments(bar.to_segments)
      @console.write(" #{percentage} • #{elapsed}")
    end

    def format_time(seconds)
      mins = (seconds / 60).floor
      secs = (seconds % 60).floor
      format("%d:%02d", mins, secs)
    end
  end
end
