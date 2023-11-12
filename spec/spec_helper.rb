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
