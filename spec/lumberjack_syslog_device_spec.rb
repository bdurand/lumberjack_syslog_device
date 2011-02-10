require 'spec_helper'

describe Lumberjack::SyslogDevice do
  
  let(:time){ Time.parse("2011-02-01T18:32:31Z") }
  let(:entry){ Lumberjack::LogEntry.new(time, Lumberjack::Severity::WARN, "message 1", "lumberjack_syslog_device_spec", 12345, "ABCD") }

  context "open connecton" do  
    it "should be able to specify syslog options" do
      syslog = MockSyslog.new
      device = Lumberjack::SyslogDevice.new(:options => Syslog::LOG_CONS)
      Syslog.should_receive(:open).with(entry.progname, Syslog::LOG_CONS, nil).and_return(syslog)
      device.write(entry)
    end
  
    it "should be able to specify a syslog facility" do
      syslog = MockSyslog.new
      device = Lumberjack::SyslogDevice.new(:facility => Syslog::LOG_FTP)
      Syslog.should_receive(:open).with(entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), Syslog::LOG_FTP).and_return(syslog)
      device.write(entry)
    end
  
    it "should log all messages since the logger will filter them by severity" do
      syslog = MockSyslog.new
      device = Lumberjack::SyslogDevice.new
      Syslog.should_receive(:open).with(entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), nil).and_return(syslog)
      device.write(entry)
      syslog.mask.should == Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
    end
  end
  
  context "logging" do
    it "should log entries to syslog" do
      entry.unit_of_work_id = nil
      device = Lumberjack::SyslogDevice.new
      messages = read_syslog do
        device.write(entry)
      end
      messages.first.should include("message 1")
    end
  
    it "should log output to syslog with the unit of work id if it exists" do
      device = Lumberjack::SyslogDevice.new
      messages = read_syslog do
        device.write(entry)
      end
      messages.first.should include("message 1 (#ABCD)")
    end
  
    it "should be able to specify a string template" do
      device = Lumberjack::SyslogDevice.new(:template => ":unit_of_work_id - :message")
      messages = read_syslog do
        device.write(entry)
      end
      messages.first.should include("ABCD - message 1")
    end
  
    it "should be able to specify a proc template" do
      device = Lumberjack::SyslogDevice.new(:template => lambda{|e| e.message.upcase})
      messages = read_syslog do
        device.write(entry)
      end
      messages.first.should include("MESSAGE 1")
    end
  
    it "should properly handle percent signs in the syslog message" do
      device = Lumberjack::SyslogDevice.new
      entry.message = "message 100%"
      messages = read_syslog do
        device.write(entry)
      end
      messages.first.should include("message 100% (#ABCD)")
    end
  
    it "should convert lumberjack severities to syslog severities" do
      syslog = MockSyslog.new
      device = Lumberjack::SyslogDevice.new
      Syslog.stub!(:open).and_return(syslog)
      syslog.should_receive(:log).with(Syslog::LOG_DEBUG, "debug")
      syslog.should_receive(:log).with(Syslog::LOG_INFO, "info")
      syslog.should_receive(:log).with(Syslog::LOG_WARNING, "warn")
      syslog.should_receive(:log).with(Syslog::LOG_ERR, "error")
      syslog.should_receive(:log).with(Syslog::LOG_CRIT, "fatal")
      device.write(Lumberjack::LogEntry.new(Time.now, Lumberjack::Severity::DEBUG, "debug", "lumberjack_syslog_device_spec", 12345, nil))
      device.write(Lumberjack::LogEntry.new(Time.now, Lumberjack::Severity::INFO, "info", "lumberjack_syslog_device_spec", 12345, nil))
      device.write(Lumberjack::LogEntry.new(Time.now, Lumberjack::Severity::WARN, "warn", "lumberjack_syslog_device_spec", 12345, nil))
      device.write(Lumberjack::LogEntry.new(Time.now, Lumberjack::Severity::ERROR, "error", "lumberjack_syslog_device_spec", 12345, nil))
      device.write(Lumberjack::LogEntry.new(Time.now, Lumberjack::Severity::FATAL, "fatal", "lumberjack_syslog_device_spec", 12345, nil))
    end
    
    it "should log messages with the syslog ident set to the progname" do
      device = Lumberjack::SyslogDevice.new
      messages = read_syslog("lumberjack_syslog_device") do
        device.write(entry)
        entry.progname = "spec_for_lumberjack_syslog_device"
        entry.message = "new message"
        device.write(entry)
      end
      messages.first.should include("lumberjack_syslog_device_spec")
      messages.last.should include("spec_for_lumberjack_syslog_device")
    end
    
    it "should keep open the syslog connection by default" do
      device = Lumberjack::SyslogDevice.new
      messages = read_syslog do
        device.write(entry)
        Syslog.should be_opened
      end
    end
    
    it "should close the syslog connection if :close_connection is true" do
      device = Lumberjack::SyslogDevice.new(:close_connection => true)
      messages = read_syslog do
        device.write(entry)
        Syslog.should_not be_opened
      end
    end
  end
end
