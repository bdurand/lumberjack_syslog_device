# frozen_string_literal: true

require "syslog"
require "lumberjack"

# Lumberjack is a simple, powerful, and very fast logging utility that can be a drop
# in replacement for Logger or ActiveSupport::BufferedLogger.
module Lumberjack
  # This Lumberjack device logs output to syslog. There can only be one connection to syslog
  # open at a time. If you use syslog elsewhere in your application, you'll need to pass
  # :close_connection => true to the constructor. Otherwise, the connection will be kept
  # open between +write+ calls.
  class SyslogDevice < Device
    VERSION = ::File.read(::File.join(__dir__, "..", "..", "VERSION")).strip.freeze

    # Mapping of Lumberjack severity levels to syslog priority levels
    SEVERITY_MAP = {
      Severity::TRACE => Syslog::LOG_DEBUG,
      Severity::DEBUG => Syslog::LOG_DEBUG,
      Severity::INFO => Syslog::LOG_INFO,
      Severity::WARN => Syslog::LOG_WARNING,
      Severity::ERROR => Syslog::LOG_ERR,
      Severity::FATAL => Syslog::LOG_CRIT,
      Severity::UNKNOWN => Syslog::LOG_ALERT
    }

    # Literal percent character
    PERCENT = "%"
    # Escaped percent character for syslog format strings
    ESCAPED_PERCENT = "%%"

    # Default template for formatting log messages
    DEFAULT_TEMPLATE = ":message :attributes"
    # Default format for rendering log entry attributes
    DEFAULT_ATTRIBUTE_FORMAT = "[%s:%s]"

    DeviceRegistry.add(:syslog, self)

    @@lock = Mutex.new

    # Create a new SyslogDevice. The options control how messages are written to syslog.
    #
    # The template can be specified using the :template option. This can
    # either be a Proc or a string that will compile into a Template object.
    # If the template is a Proc, it should accept an LogEntry as its only argument and output a string.
    # If the template is a template string, it will be used to create a Template.
    # The default template is `:message :attributes`.
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
      @template = options[:template] || DEFAULT_TEMPLATE
      attribute_format = options[:attribute_format] || DEFAULT_ATTRIBUTE_FORMAT
      @template = Template.new(@template, attribute_format: attribute_format) if @template.is_a?(String)

      @syslog_options = options[:options] || (Syslog::LOG_PID | Syslog::LOG_CONS)
      @syslog_facility = options[:facility]
      @close_connection = options[:close_connection]
      @syslog_identity = nil
    end

    # Write a log entry to syslog.
    #
    # @param entry [Lumberjack::LogEntry] the log entry to write
    # @return [void]
    def write(entry)
      message = @template.call(entry).to_s.chomp.gsub(PERCENT, ESCAPED_PERCENT)
      @@lock.synchronize do
        syslog = open_syslog(entry.progname)
        begin
          syslog.log(SEVERITY_MAP[entry.severity], message)
        ensure
          syslog.close if @close_connection
        end
      end
    end

    # Close the syslog connection.
    #
    # @return [void]
    def close
      flush
      @lock.synchronize do
        @syslog.close if @syslog&.opened?
      end
    end

    private

    # Open syslog with ident set to progname. If it is already open with a different
    # ident, close it and reopen it.
    def open_syslog(progname) # :nodoc:
      syslog_impl = syslog_implementation
      if syslog_impl.opened?
        if (progname.nil? || syslog_impl.ident == progname.to_s) && @syslog_facility == syslog_impl.facility && @syslog_options == syslog_impl.options
          return syslog_impl
        else
          syslog_impl.close
        end
      end
      syslog = syslog_impl.open(progname.to_s, @syslog_options, @syslog_facility)
      syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
      syslog
    end

    # Provided for testing purposes
    def syslog_implementation # :nodoc:
      Syslog
    end
  end
end
