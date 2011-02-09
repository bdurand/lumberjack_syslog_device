require File.expand_path("../../lib/lumberjack_syslog_device.rb", __FILE__)

SYSLOG_FILE = ENV["SYSLOG_FILE"] || "/var/log/system.log"

# Round about way of reading syslog by following it using the command line and looking in the output.
def read_syslog(progname = "lumberjack_syslog_device_spec")
  message_id = rand(0xFFFFFFFFFFFFFFFF)
  Syslog.open("lumberjack_syslog_device_spec") do |syslog|
    syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
    syslog.warning("************** start #{message_id}")
  end
  yield
  Syslog.close if Syslog.opened?
  Syslog.open("lumberjack_syslog_device_spec") do |syslog|
    syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
    syslog.warning("************** end #{message_id}")
  end
  sleep(0.5)
  lines = `tail -200 #{SYSLOG_FILE}`.split("\n")
  retval = nil
  lines.each do |line|
    if line.include?("start #{message_id}")
      retval = []
    elsif line.include?("end #{message_id}")
      break
    else
      retval << line if retval && line.include?(progname)
    end
  end
  retval
end

class MockSyslog
  attr_accessor :mask
  attr_reader :ident, :options, :facility

  def open(ident, options, facility)
    @ident = ident
    @options = options
    @facility = facility
  end

  def log(*args)
  end
end
