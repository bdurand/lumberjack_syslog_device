require_relative "../lib/lumberjack_syslog_device"

# Mock object for testing Syslog since it's not available on many systems.
class MockSyslog
  attr_reader :ident, :options, :facility, :mask, :output

  def initialize
    @output = []
    @opened = false
  end

  def open(ident, options, facility)
    @ident = ident
    @options = options
    @facility = facility
    @opened = true
    self
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
