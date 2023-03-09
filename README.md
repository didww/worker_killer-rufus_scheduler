# WorkerKiller::RufusScheduler

[Worker killer](https://github.com/RND-SOFT/worker_killer) extension for [Rufus::Scheduler](https://github.com/jmettraux/rufus-scheduler) standalone process.
When process hits RAM limit killer tries to shutdown gracefully until timeout.
After timeout it force scheduler to shutdown.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add worker_killer-rufus_scheduler

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install worker_killer-rufus_scheduler

## Usage

```ruby
require 'rufus-scheduler'
require 'worker_killer/rufus_scheduler'

scheduler = Rufus::Scheduler.new

# ...

WorkerKiller::RufusScheduler::Job::OOMLimiter.register(
  scheduler: scheduler,
  frequency: 30, # check every 30 seconds
  timeout: 120, # wait 120 seconds until jobs finish, after that kill them
  min: (1024**2)*475, # RAM limit chosen randomly between 475mb and 525mb
  max: (1024**2)*525,
  verbose: true
)

scheduler.join
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/didww/worker_killer-rufus_scheduler.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
