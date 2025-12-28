# frozen_string_literal: true

require "json"
require "time"

module AsciinemaWin
  # Asciicast v2 file format handling
  #
  # This module implements the asciicast v2 specification for terminal recordings.
  # Format: newline-delimited JSON (NDJSON)
  # - Line 1: Header object with metadata
  # - Lines 2+: Event arrays [time, type, data]
  #
  # @see https://docs.asciinema.org/manual/asciicast/v2/
  module Asciicast
    # Asciicast format version
    VERSION = 2

    # File extension
    EXTENSION = ".cast"

    # MIME type
    MIME_TYPE = "application/x-asciicast"

    # Event type constants
    module EventType
      # Output data written to terminal
      OUTPUT = "o"
      # Input data read from terminal
      INPUT = "i"
      # Terminal resize event
      RESIZE = "r"
      # Marker/bookmark
      MARKER = "m"
    end

    # Recording header with metadata
    #
    # @example Create a header
    #   header = Header.new(
    #     width: 120,
    #     height: 30,
    #     title: "Demo Recording"
    #   )
    class Header
      # @return [Integer] Format version (always 2)
      attr_accessor :version

      # @return [Integer] Terminal width in columns
      attr_accessor :width

      # @return [Integer] Terminal height in rows
      attr_accessor :height

      # @return [Integer, nil] Unix timestamp of recording start
      attr_accessor :timestamp

      # @return [Float, nil] Total duration in seconds
      attr_accessor :duration

      # @return [Float, nil] Maximum idle time between frames
      attr_accessor :idle_time_limit

      # @return [String, nil] Command that was recorded
      attr_accessor :command

      # @return [String, nil] Recording title
      attr_accessor :title

      # @return [Hash<String, String>] Captured environment variables
      attr_accessor :env

      # @return [Hash, nil] Terminal color theme
      attr_accessor :theme

      # Create a new header
      #
      # @param width [Integer] Terminal width
      # @param height [Integer] Terminal height
      # @param timestamp [Integer, nil] Unix timestamp (defaults to now)
      # @param duration [Float, nil] Recording duration
      # @param idle_time_limit [Float, nil] Max idle time
      # @param command [String, nil] Recorded command
      # @param title [String, nil] Recording title
      # @param env [Hash, nil] Environment variables
      # @param theme [Hash, nil] Color theme
      def initialize(
        width:,
        height:,
        timestamp: nil,
        duration: nil,
        idle_time_limit: nil,
        command: nil,
        title: nil,
        env: nil,
        theme: nil
      )
        @version = VERSION
        @width = width
        @height = height
        @timestamp = timestamp || Time.now.to_i
        @duration = duration
        @idle_time_limit = idle_time_limit
        @command = command
        @title = title
        @env = env || {}
        @theme = theme
      end

      # Serialize header to JSON string
      #
      # @return [String] JSON representation
      def to_json(*_args)
        data = {
          "version" => @version,
          "width" => @width,
          "height" => @height
        }

        # Add optional fields only if present
        data["timestamp"] = @timestamp if @timestamp
        data["duration"] = @duration if @duration
        data["idle_time_limit"] = @idle_time_limit if @idle_time_limit
        data["command"] = @command if @command
        data["title"] = @title if @title
        data["env"] = @env unless @env.empty?
        data["theme"] = @theme if @theme

        JSON.generate(data)
      end

      # Parse header from JSON string
      #
      # @param json_str [String] JSON string
      # @return [Header] Parsed header
      # @raise [FormatError] If JSON is invalid or required fields are missing
      def self.from_json(json_str)
        data = JSON.parse(json_str)

        unless data.is_a?(Hash)
          raise FormatError, "Header must be a JSON object"
        end

        version = data["version"]
        unless version == VERSION
          raise FormatError, "Unsupported asciicast version: #{version}. Expected: #{VERSION}"
        end

        width = data["width"]
        height = data["height"]

        unless width.is_a?(Integer) && width > 0
          raise FormatError, "Invalid width: #{width}"
        end

        unless height.is_a?(Integer) && height > 0
          raise FormatError, "Invalid height: #{height}"
        end

        new(
          width: width,
          height: height,
          timestamp: data["timestamp"],
          duration: data["duration"]&.to_f,
          idle_time_limit: data["idle_time_limit"]&.to_f,
          command: data["command"],
          title: data["title"],
          env: data["env"] || {},
          theme: data["theme"]
        )
      rescue JSON::ParserError => e
        raise FormatError, "Invalid header JSON: #{e.message}"
      end

      # @return [Hash] Header as a hash
      def to_h
        {
          version: @version,
          width: @width,
          height: @height,
          timestamp: @timestamp,
          duration: @duration,
          idle_time_limit: @idle_time_limit,
          command: @command,
          title: @title,
          env: @env,
          theme: @theme
        }
      end
    end

    # Single recording event
    #
    # @example Output event
    #   event = Event.new(0.5, EventType::OUTPUT, "Hello, World!")
    #
    # @example Resize event
    #   event = Event.new(1.0, EventType::RESIZE, "120x40")
    class Event
      # @return [Float] Time offset in seconds from recording start
      attr_reader :time

      # @return [String] Event type (o, i, r, m)
      attr_reader :type

      # @return [String] Event data
      attr_reader :data

      # Create a new event
      #
      # @param time [Float] Time offset in seconds
      # @param type [String] Event type
      # @param data [String] Event data
      def initialize(time, type, data)
        @time = time.to_f
        @type = type.to_s
        @data = data.to_s
      end

      # Serialize event to JSON array string
      #
      # @return [String] JSON array representation
      def to_json(*_args)
        JSON.generate([@time, @type, @data])
      end

      # Parse event from JSON string
      #
      # @param json_str [String] JSON array string
      # @return [Event] Parsed event
      # @raise [FormatError] If format is invalid
      def self.from_json(json_str)
        data = JSON.parse(json_str)

        unless data.is_a?(Array) && data.length >= 3
          raise FormatError, "Event must be a JSON array with 3 elements"
        end

        new(data[0], data[1], data[2])
      rescue JSON::ParserError => e
        raise FormatError, "Invalid event JSON: #{e.message}"
      end

      # Check if this is an output event
      # @return [Boolean]
      def output?
        @type == EventType::OUTPUT
      end

      # Check if this is an input event
      # @return [Boolean]
      def input?
        @type == EventType::INPUT
      end

      # Check if this is a resize event
      # @return [Boolean]
      def resize?
        @type == EventType::RESIZE
      end

      # Check if this is a marker event
      # @return [Boolean]
      def marker?
        @type == EventType::MARKER
      end

      # Get resize dimensions (for resize events)
      # @return [Array<Integer>, nil] [width, height] or nil if not a resize event
      def resize_dimensions
        return nil unless resize?

        parts = @data.split("x")
        return nil unless parts.length == 2

        [parts[0].to_i, parts[1].to_i]
      end

      # @return [Hash] Event as a hash
      def to_h
        { time: @time, type: @type, data: @data }
      end
    end

    # Writer for creating asciicast recordings
    #
    # @example Write a recording
    #   header = Asciicast::Header.new(width: 80, height: 24)
    #   File.open("recording.cast", "w") do |file|
    #     writer = Asciicast::Writer.new(file, header)
    #     writer.write_output(0.0, "Hello\r\n")
    #     writer.write_output(0.5, "World\r\n")
    #     writer.close
    #   end
    class Writer
      # @return [Header] Recording header
      attr_reader :header

      # @return [Float] Last event time (for duration calculation)
      attr_reader :last_event_time

      # Create a new writer
      #
      # @param io [IO] Output stream
      # @param header [Header] Recording header
      def initialize(io, header)
        @io = io
        @header = header
        @last_event_time = 0.0
        @closed = false
        @event_count = 0

        # Write header immediately
        write_header
      end

      # Write an output event
      #
      # @param time [Float] Time offset in seconds
      # @param data [String] Output data
      # @return [void]
      def write_output(time, data)
        write_event(Event.new(time, EventType::OUTPUT, data))
      end

      # Write an input event
      #
      # @param time [Float] Time offset in seconds
      # @param data [String] Input data
      # @return [void]
      def write_input(time, data)
        write_event(Event.new(time, EventType::INPUT, data))
      end

      # Write a resize event
      #
      # @param time [Float] Time offset in seconds
      # @param width [Integer] New width
      # @param height [Integer] New height
      # @return [void]
      def write_resize(time, width, height)
        write_event(Event.new(time, EventType::RESIZE, "#{width}x#{height}"))
      end

      # Write a marker event
      #
      # @param time [Float] Time offset in seconds
      # @param label [String] Marker label
      # @return [void]
      def write_marker(time, label = "")
        write_event(Event.new(time, EventType::MARKER, label))
      end

      # Write a generic event
      #
      # @param event [Event] Event to write
      # @return [void]
      def write_event(event)
        raise RecordingError, "Writer is closed" if @closed

        @io.puts(event.to_json)
        @last_event_time = event.time
        @event_count += 1
      end

      # Close the writer and finalize the recording
      #
      # @return [void]
      def close
        return if @closed

        @closed = true
        @io.flush if @io.respond_to?(:flush)
      end

      # @return [Boolean] Whether the writer is closed
      def closed?
        @closed
      end

      # @return [Integer] Number of events written
      def event_count
        @event_count
      end

      private

      # Write the header line
      def write_header
        @io.puts(@header.to_json)
      end
    end

    # Reader for playing back asciicast recordings
    #
    # @example Read a recording
    #   File.open("recording.cast", "r") do |file|
    #     reader = Asciicast::Reader.new(file)
    #     puts "Recording: #{reader.header.title}"
    #     reader.each_event do |event|
    #       puts "#{event.time}: #{event.type}"
    #     end
    #   end
    class Reader
      # @return [Header] Recording header
      attr_reader :header

      # Create a new reader
      #
      # @param io [IO] Input stream
      # @raise [FormatError] If header is invalid
      def initialize(io)
        @io = io
        @header = read_header
        @events_started = false
      end

      # Get recording info from a file path
      #
      # @param path [String] Path to recording file
      # @return [Hash] Recording metadata
      # @raise [FormatError] If file is invalid
      def self.info(path)
        File.open(path, "r", encoding: "UTF-8") do |file|
          reader = new(file)
          header = reader.header

          # Count events and calculate duration
          event_count = 0
          last_time = 0.0

          reader.each_event do |event|
            event_count += 1
            last_time = event.time
          end

          {
            version: header.version,
            width: header.width,
            height: header.height,
            timestamp: header.timestamp,
            duration: header.duration || last_time,
            idle_time_limit: header.idle_time_limit,
            command: header.command,
            title: header.title,
            env: header.env,
            theme: header.theme,
            event_count: event_count
          }
        end
      end

      # Iterate over all events in the recording
      #
      # @yield [Event] Each event in order
      # @return [Enumerator, void] If no block given, returns an Enumerator
      def each_event
        return enum_for(:each_event) unless block_given?

        @events_started = true

        @io.each_line do |line|
          line = line.strip
          next if line.empty?

          begin
            event = Event.from_json(line)
            yield event
          rescue FormatError
            # Skip invalid lines (could be comments or garbage)
            next
          end
        end
      end

      # Read all events into an array
      #
      # @return [Array<Event>] All events
      def events
        each_event.to_a
      end

      # Get total duration of the recording
      #
      # @return [Float] Duration in seconds
      def duration
        return @header.duration if @header.duration

        # Calculate from events
        last_time = 0.0
        each_event { |e| last_time = e.time }
        last_time
      end

      private

      # Read and parse the header line
      #
      # @return [Header] Parsed header
      # @raise [FormatError] If header is invalid
      def read_header
        line = @io.readline
        Header.from_json(line.strip)
      rescue EOFError
        raise FormatError, "Empty file: no header found"
      end
    end

    # Create a recording from a file path with a block
    #
    # @param path [String] Output file path
    # @param width [Integer] Terminal width
    # @param height [Integer] Terminal height
    # @param kwargs [Hash] Additional header options
    # @yield [Writer] Writer for adding events
    # @return [void]
    def self.create(path, width:, height:, **kwargs)
      header = Header.new(width: width, height: height, **kwargs)

      File.open(path, "w", encoding: "UTF-8") do |file|
        writer = Writer.new(file, header)
        yield writer if block_given?
        writer.close
      end
    end

    # Load a recording from a file path
    #
    # @param path [String] Input file path
    # @return [Reader] Reader for the recording
    # @raise [FormatError] If file is invalid
    def self.load(path)
      file = File.open(path, "r", encoding: "UTF-8")
      Reader.new(file)
    end
  end
end
