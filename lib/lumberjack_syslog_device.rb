require 'syslog'
require 'lumberjack'

module Lumberjack
  class SyslogDevice < Device
    SEVERITY_MAP = {
      Severity::DEBUG => Syslog::LOG_DEBUG,
      Severity::INFO => Syslog::LOG_INFO,
      Severity::WARN => Syslog::LOG_WARNING,
      Severity::ERROR => Syslog::LOG_ERR,
      Severity::FATAL => Syslog::LOG_CRIT,
      Severity::UNKNOWN => Syslog::LOG_ALERT
    }
    
    PERCENT = '%'
    ESCAPED_PERCENT = '%%'
    
    def initialize(options = {})
      @template = options[:template] || lambda{|entry| entry.unit_of_work_id ? "#{entry.message} (##{entry.unit_of_work_id})" : entry.message}
      @template = Template.new(@template) if @template.is_a?(String)
      @syslog_options = options[:options] || (Syslog::LOG_PID | Syslog::LOG_CONS)
      @syslog_facility = options[:facility]
    end
    
    def write(entry)
      message = @template.call(entry).gsub(PERCENT, ESCAPED_PERCENT)
      Syslog.open(entry.progname, @syslog_options, @syslog_facility) do |syslog|
        syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
        syslog.log(SEVERITY_MAP[entry.severity], message)
      end
    end
  end
end
