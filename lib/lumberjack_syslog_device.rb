# frozen_string_literal: true

require 'syslog'
require 'lumberjack'

module Lumberjack
  # This Lumberjack device logs output to syslog. There can only be one connection to syslog
  # open at a time. If you use syslog elsewhere in your application, you'll need to pass
  # :close_connection => true to the constructor. Otherwise, the connection will be kept
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
    # The template can be specified using the :template option. This can
    # either be a Proc or a string that will compile into a Template object.
    # If the template is a Proc, it should accept an LogEntry as its only argument and output a string.
    # If the template is a template string, it will be used to create a Template.
    # The default template is ":message (#:unit_of_work_id)".
    #
    # The :close_connection option can be used to specify that the connection to syslog should be
    # closed after every +write+ call. This will slow down performance, but will allow you to use syslog
    # elsewhere in your application.
    #
    # The :options option will pass through options to syslog. The default is
    # Syslog::LOG_PID | Syslog::LOG_CONS. Available values for the bit map are:
    # * Syslog::LOG_CONS - Write directly to system console if there is an error while sending to system logger.
    # * Syslog::LOG_NDELAY - Open the connection immediately (normally, the connection is opened when the first message is logged).
    # * Syslog::LOG_NOWAIT - Don't wait for child processes that may have been created while logging the message.
    # * Syslog::LOG_ODELAY - The converse of LOG_NDELAY; opening of the connection is delayed.
    # * Syslog::LOG_PERROR - Print to stderr as well.
    # * Syslog::LOG_PID - Include PID with each message.
    #
    # The :facility option will pass through a facility to syslog. Available values are
    # * Syslog::LOG_AUTH
    # * Syslog::LOG_AUTHPRIV
    # * Syslog::LOG_CRON
    # * Syslog::LOG_DAEMON
    # * Syslog::LOG_FTP
    # * Syslog::LOG_KERN
    # * Syslog::LOG_LOCAL0 through Syslog::LOG_LOCAL7
    # * Syslog::LOG_LPR
    # * Syslog::LOG_MAIL
    # * Syslog::LOG_NEWS
    # * Syslog::LOG_SYSLOG
    # * Syslog::LOG_USER (default)
    # * Syslog::LOG_UUCP
    def initialize(options = {})
      @template = options[:template] || default_template
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
      syslog_impl = syslog_implementation
      if syslog_impl.opened?
        if (progname.nil? || syslog_impl.ident == progname) && @syslog_facility == syslog_impl.facility && @syslog_options == syslog_impl.options
          return syslog_impl
        else
          syslog_impl.close
        end
      end
      syslog = syslog_impl.open(progname, @syslog_options, @syslog_facility)
      syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
      syslog
    end

    # Provided for testing purposes
    def syslog_implementation #:nodoc:
      Syslog
    end

    def default_template
      lambda do |entry|
        tags = entry.tags
        if tags && !tags.empty?
          message = String.new(entry.message)
          message << " (#{entry.unit_of_work_id})" if entry.unit_of_work_id
          tags.each do |name, value|
            message << " [#{name}:#{value.inspect}]" unless name == Lumberjack::LogEntry::UNIT_OF_WORK_ID
          end
          message
        else
          entry.message
        end
      end
    end
  end
end
