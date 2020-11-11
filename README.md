# xcactivitylog

Easy parse Xcode's `.xcactivitylog` files!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xcactivitylog'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install xcactivitylog

## Usage

```ruby
require 'xcactivitylog'

toplevel_sections = XCActivityLog.parse_file(path: 'path/to/log.xcactivitylog')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/segiddins/xcactivitylog. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## New Xcode versions

As new versions of Xcode come out it might be necessary to handle new private API, the parser will fail and the name of the unhandled class can be found in the error message as `#<NameError: uninitialized constant <CLASS_NAME>`.

One way to fix it is to create a dummy project using the new Xcode version and generate a `.xcactivitylog` that allows one to reproduce the same error, the logs can be found in Xcode's `DerivedData` folder (`~/Library/Developer/Xcode/DerivedData/{UUID}/Logs/Build`). Manually parse the `.xcactivitylog` file, check the `version` at the top and then for `version = X` create a folder `spec/fixtures/xcactivitylog/vX` and puth the `.xcactivitylog` in there.

Now `rake spec` will try to parse the new log file and it should fail with the same exception above. Make the necessary code changes to handle the new class (it might help to check for class dumps like these [here](https://github.com/segiddins/Xcode-RuntimeHeaders)). Once the proper changes are in `rake spec` should go green.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Xcactivitylog project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/segiddins/xcactivitylog/blob/master/CODE_OF_CONDUCT.md).
