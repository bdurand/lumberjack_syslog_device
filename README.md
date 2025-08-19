# Lumberjack Syslog Device

[![Continuous Integration](https://github.com/bdurand/lumberjack_syslog_device/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/lumberjack_syslog_device/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/lumberjack_syslog_device.svg)](https://badge.fury.io/rb/lumberjack_syslog_device)

This gem provides a logging device for the [lumberjack](https://github.com/bdurand/lumberjack) gem that will log to syslog, the centralized system logging facility. See http://en.wikipedia.org/wiki/Syslog for more information on syslog.

## Usage

```ruby
require 'lumberjack_syslog_device'

device = Lumberjack::SyslogDevice.new
logger = Lumberjack::Logger.new(device)
logger.info("Write me to syslog!")
```

See the docs in the Lumberjack::SyslogDevice file for more details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lumberjack_syslog_device'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install lumberjack_syslog_device
```

## Contributing

Open a pull request on GitHub.

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
