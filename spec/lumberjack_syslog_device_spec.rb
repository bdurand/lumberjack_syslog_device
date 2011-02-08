require 'spec_helper'

describe Lumberjack::SyslogDevice do
  
  let(:time){ Time.parse("2011-02-01T18:32:31Z") }
  let(:entry){ Lumberjack::LogEntry.new(time, Lumberjack::Severity::INFO, "message 1", "lumberjack_syslog_device_spec", 12345, "ABCD") }
  
  class MockSyslog
    attr_accessor :mask
    def log(*args)
    end
  end
  
  it "should log output to syslog" do
    simple_entry = Lumberjack::LogEntry.new(time, Lumberjack::Severity::INFO, "message 1", "lumberjack_syslog_device_spec", 12345, nil)
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new
    Syslog.should_receive(:open).with(simple_entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), nil).and_yield(syslog)
    syslog.should_receive(:log).with(Syslog::LOG_INFO, simple_entry.message)
    device.write(simple_entry)
  end
  
  it "should log output to syslog with the unit of work id if it exists" do
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new
    Syslog.should_receive(:open).with(entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), nil).and_yield(syslog)
    syslog.should_receive(:log).with(Syslog::LOG_INFO, "message 1 (#ABCD)")
    device.write(entry)
  end
  
  it "should be able to specify a string template" do
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new(:template => ":unit_of_work_id - :message")
    Syslog.should_receive(:open).with(entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), nil).and_yield(syslog)
    syslog.should_receive(:log).with(Syslog::LOG_INFO, "ABCD - message 1")
    device.write(entry)
  end
  
  it "should be able to specify a proc template" do
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new(:template => lambda{|e| e.message.upcase})
    Syslog.should_receive(:open).with(entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), nil).and_yield(syslog)
    syslog.should_receive(:log).with(Syslog::LOG_INFO, "MESSAGE 1")
    device.write(entry)
  end
  
  it "should be able to specify syslog options" do
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new(:options => Syslog::LOG_CONS)
    Syslog.should_receive(:open).with(entry.progname, Syslog::LOG_CONS, nil).and_yield(syslog)
    device.write(entry)
  end
  
  it "should be able to specify a syslog facility" do
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new(:facility => Syslog::LOG_FTP)
    Syslog.should_receive(:open).with(entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), Syslog::LOG_FTP).and_yield(syslog)
    device.write(entry)
  end
  
  it "should log all messages since the logger will filter them by severity" do
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new
    Syslog.should_receive(:open).with(entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), nil).and_yield(syslog)
    device.write(entry)
    syslog.mask.should == Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
  end
  
  it "should escape percent signs in the syslog message" do
    simple_entry = Lumberjack::LogEntry.new(time, Lumberjack::Severity::INFO, "100% done with 10%", "lumberjack_syslog_device_spec", 12345, nil)
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new
    Syslog.should_receive(:open).with(simple_entry.progname, (Syslog::LOG_PID | Syslog::LOG_CONS), nil).and_yield(syslog)
    syslog.should_receive(:log).with(Syslog::LOG_INFO, "100%% done with 10%%")
    device.write(simple_entry)
  end
  
  it "should convert lumberjack severities to syslog severities" do
    syslog = MockSyslog.new
    device = Lumberjack::SyslogDevice.new
    Syslog.stub!(:open).and_yield(syslog)
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
  
  it "should actually log messages" do
    device = Lumberjack::SyslogDevice.new
    message = "************** #{rand(0xFFFFFFFFFFFFFFFF)}"
    device.write(Lumberjack::LogEntry.new(Time.now, Lumberjack::Severity::WARN, message, "lumberjack_syslog_device_spec", $$, nil))
    tmp_file = File.expand_path("../syslog.tmp", __FILE__)
    pid = fork do
      `syslog -w 1000 > #{tmp_file}`
    end
    stop_time = Time.now + 10
    messages = nil
    loop do
      messages = File.read(tmp_file) if File.exist?(tmp_file)
      break if messages.include?(message) || Time.now > stop_time
      sleep(0.01)
    end
    Process.kill(15, pid)
    File.delete(tmp_file)
    messages.should include(message)
  end
  
end
