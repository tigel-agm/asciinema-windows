# frozen_string_literal: true

require_relative "lib/asciinema_win/version"

Gem::Specification.new do |spec|
  spec.name          = "asciinema_win"
  spec.version       = AsciinemaWin::VERSION
  spec.authors       = ["tigel-agm"]
  spec.email         = ["tigel-agm"]

  spec.summary       = "Native Windows terminal recorder with video export in pure Ruby"
  spec.description   = "Zero-dependency terminal recording and playback for Windows. " \
                       "Records sessions with accurate timing, exports to asciicast v2 (compatible with asciinema.org). " \
                       "v0.2.0: Export to GIF/MP4/WebM video (FFmpeg), pure Ruby PPM renderer with embedded VGA font, " \
                       "9 terminal themes, Rich-Ruby integration, full ANSI color support (16/256/TrueColor)."

  spec.homepage      = "https://github.com/tigel-agm/asciinema-windows"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "#{spec.homepage}#readme",
    "rubygems_mfa_required" => "true"
  }

  # Only include files that are part of the gem
  spec.files = Dir.chdir(__dir__) do
    Dir["{exe,lib,docs}/**/*", "README.md", "LICENSE", "CHANGELOG.md"].reject do |f|
      File.directory?(f) ||
        f.end_with?(".gem") ||
        f.include?("test/") ||
        f.include?("spec/")
    end
  end

  spec.bindir        = "exe"
  spec.executables   = ["asciinema_win"]
  spec.require_paths = ["lib"]

  # Zero runtime dependencies - uses only Ruby standard library
  # Dependencies used:
  # - Fiddle (stdlib) - Windows API bindings
  # - JSON (stdlib) - asciicast format
  # - StringIO (stdlib) - buffer management

  # Development dependencies (optional, for contributors)
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
