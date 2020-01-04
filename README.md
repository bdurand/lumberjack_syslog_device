# Lumberjack Syslog Device

[![Build Status](https://travis-ci.org/bdurand/lumberjack_syslog_device.svg?branch=master)](https://travis-ci.org/bdurand/lumberjack_syslog_device)
[![Maintainability](https://api.codeclimate.com/v1/badges/61785ec7e33012f55d65/maintainability)](https://codeclimate.com/github/bdurand/lumberjack_syslog_device/maintainability)

This gem provides a logging device for the [lumberjack](https://github.com/bdurand/lumberjack) gem that will log to syslog, the centralized system logging facility. See http://en.wikipedia.org/wiki/Syslog for more information on syslog.

## Example Usage

```ruby
require 'lumberjack_syslog_device'

device = Lumberjack::SyslogDevice.new
logger = Lumberjack::Logger.new(device)
logger.info("Write me to syslog!")
```

See SyslogDevice for more details.
