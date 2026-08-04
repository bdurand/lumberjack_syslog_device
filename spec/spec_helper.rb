# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

begin
  require "simplecov"
  SimpleCov.start do
    add_filter ["/spec/"]
  end
rescue LoadError
end

Bundler.require(:default, :test)

require_relative "../lib/lumberjack_syslog_device"

# Mock object for testing Syslog since it's not available on many systems.
class MockSyslog
  attr_reader :ident, :options, :facility, :mask, :output, :open_count

  def initialize
    @output = []
    @opened = false
    @open_count = 0
  end

  def open(ident, options, facility)
    raise "syslog already open" if @opened

    @ident = ident
    @options = options
    # Syslog defaults a nil facility to LOG_USER.
    @facility = facility || Syslog::LOG_USER
    @opened = true
    @open_count += 1
    self
  end

  def close
    @opened = false
  end

  def opened?
    @opened
  end

  attr_writer :mask

  def log(severity, message)
    @output << [severity, message]
  end
end

Lumberjack.deprecation_mode = :raise
Lumberjack.raise_logger_errors = true

RSpec.configure do |config|
  config.warnings = true
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end
