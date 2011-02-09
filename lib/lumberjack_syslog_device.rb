require 'syslog'
require 'lumberjack'

module Lumberjack
  # This Lumberjack device logs output to syslog. There can only be one connection to syslog
  # open at a time. If you use syslog elsewhere in your application, you'll need to pass
  # <tt>:close_connection => true</tt> to the constructor. Otherwise, the connection will be kept
  # open between +write+ calls.
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
    
    @@lock = Mutex.new
    
    
    # Create a new SyslogDevice. The options control how messages are written to syslog.
    #
    # The template can be specified using the <tt>:template</tt> option. This can
    # either be a Proc or a string that will compile into a Template object.
    # If the template is a Proc, it should accept an LogEntry as its only argument and output a string.
    # If the template is a template string, it will be used to create a Template.
    # The default template is <tt>":message (#:unit_of_work_id)"</tt>.
    #
    # The <tt>:close_connection</tt> option can be used to specify that the connection to syslog should be
    # closed after every +write+ call. This will slow down performance, but will allow you to use syslog
    # elsewhere in your application.
    #
    # The <tt>:options</tt> option will pass through options to syslog. The default is
    # <tt>Syslog::LOG_PID | Syslog::LOG_CONS</tt>. Available values for the bit map are:
    # * <tt>Syslog::LOG_CONS</tt> - Write directly to system console if there is an error while sending to system logger.
    # * <tt>Syslog::LOG_NDELAY</tt> - Open the connection immediately (normally, the connection is opened when the first message is logged).
    # * <tt>Syslog::LOG_NOWAIT</tt> - Don't wait for child processes that may have been created while logging the message.
    # * <tt>Syslog::LOG_ODELAY</tt> - The converse of LOG_NDELAY; opening of the connection is delayed.
    # * <tt>Syslog::LOG_PERROR</tt> - Print to stderr as well.
    # * <tt>Syslog::LOG_PID</tt> - Include PID with each message.
    #
    # The <tt>:facility</tt> option will pass through a facility to syslog. Available values are
    # * <tt>Syslog::LOG_AUTH</tt>
    # * <tt>Syslog::LOG_AUTHPRIV</tt>
    # * <tt>Syslog::LOG_CRON</tt>
    # * <tt>Syslog::LOG_DAEMON</tt>
    # * <tt>Syslog::LOG_FTP</tt>
    # * <tt>Syslog::LOG_KERN</tt>
    # * <tt>Syslog::LOG_LOCAL0</tt> through <tt>Syslog::LOG_LOCAL7</tt>
    # * <tt>Syslog::LOG_LPR</tt>
    # * <tt>Syslog::LOG_MAIL</tt>
    # * <tt>Syslog::LOG_NEWS</tt>
    # * <tt>Syslog::LOG_SYSLOG</tt>
    # * <tt>Syslog::LOG_USER</tt> (default)
    # * <tt>Syslog::LOG_UUCP</tt>
    def initialize(options = {})
      @template = options[:template] || lambda{|entry| entry.unit_of_work_id ? "#{entry.message} (##{entry.unit_of_work_id})" : entry.message}
      @template = Template.new(@template) if @template.is_a?(String)
      @syslog_options = options[:options] || (Syslog::LOG_PID | Syslog::LOG_CONS)
      @syslog_facility = options[:facility]
      @close_connection = options[:close_connection]
      @syslog_identity = nil
    end
    
    def write(entry)
      message = @template.call(entry).gsub(PERCENT, ESCAPED_PERCENT)
      @@lock.synchronize do
        syslog = open_syslog(entry.progname)
        begin
          syslog.log(SEVERITY_MAP[entry.severity], message)
        ensure
          syslog.close if @close_connection
        end
      end
    end
    
    def close
      flush
      @lock.synchronize do
        @syslog.close if @syslog && @syslog.opened?
      end
    end
    
    private
    
    # Open syslog with ident set to progname. If it is already open with a different
    # ident, close it and reopen it.
    def open_syslog(progname) #:nodoc:
      if Syslog.opened?
        if (progname.nil? || Syslog.ident == progname) && @syslog_facility == Syslog.facility && @syslog_options == Syslog.options
          return Syslog
        end
        Syslog.close
      end
      syslog = Syslog.open(progname, @syslog_options, @syslog_facility)
      syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
      syslog
    end
  end
end
