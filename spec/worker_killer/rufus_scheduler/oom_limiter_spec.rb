# frozen_string_literal: true

require 'rufus/scheduler'

RSpec.describe WorkerKiller::RufusScheduler::OOMLimiter do
  let(:one_mb) { 1024**2 }

  before { @store = [] }

  # easy way to increase RAM in test
  def increase_ram(bytes)
    @store << ('a' * bytes)
  end

  it 'shutdowns scheduler after timeout hit' do
    current_rss = GetProcessMem.new.bytes.to_i
    puts "rss #{current_rss}"
    scheduler = Rufus::Scheduler.new

    # once do something for a minute
    once = { started: [], finished: [] }
    scheduler.schedule_in('0') do
      once[:started] << true
      puts 'start: once do something for a 60 seconds'
      sleep 60
      puts 'finish: once do something for a 60 seconds'
      once[:finished] << true
    end
    every = { started: [], finished: [] }
    scheduler.every('3') do
      every[:started] << true
      puts 'start: every 3 seconds do something for 10 seconds with increase RAM by 11MB'
      increase_ram(11 * one_mb)
      puts "rss #{GetProcessMem.new.bytes.to_i}"
      sleep 10
      puts 'finish: every 3 seconds do something for 10 seconds with increase RAM by 11MB'
      every[:finished] << true
    end

    # every 3 seconds check that RAM usage less then 30mb.
    # if not stop scheduler with timeout 10
    limit = current_rss + (30 * one_mb)
    killer_timeout = 20
    described_class.register(
      scheduler: scheduler,
      frequency: 2,
      timeout: killer_timeout,
      min: limit,
      max: limit
    )

    time_before = Time.now.to_i
    scheduler_max_duration = 120
    scheduler.join(scheduler_max_duration)
    duration = Time.now.to_i - time_before

    expect(duration).to be < scheduler_max_duration
    expect(duration).to be > killer_timeout
    expect(once).to eq(started: [true], finished: [])
    expect(every).to eq(started: [true, true, true], finished: [true, true, true])
  end

  it 'shutdowns scheduler before timeout hit' do
    current_rss = GetProcessMem.new.bytes
    scheduler = Rufus::Scheduler.new

    # every 3 seconds do something for 10 seconds with increase RAM by 10MB
    every = { started: [], finished: [] }
    scheduler.every('3') do
      every[:started] << true
      puts 'start: every 3 seconds do something for 10 seconds with increase RAM by 11MB'
      increase_ram(11 * one_mb)
      puts "rss #{GetProcessMem.new.bytes.to_i}"
      sleep 10
      puts 'finish: every 3 seconds do something for 10 seconds with increase RAM by 11MB'
      every[:finished] << true
    end

    # every 3 seconds check that RAM usage less then 30mb.
    # if not stop scheduler with timeout 10
    limit = current_rss + (30 * one_mb)
    killer_timeout = 60
    described_class.register(
      scheduler: scheduler,
      frequency: 2,
      timeout: killer_timeout,
      min: limit,
      max: limit
    )

    time_before = Time.now.to_i
    scheduler_max_duration = 120
    scheduler.join(scheduler_max_duration)
    duration = Time.now.to_i - time_before

    expect(duration).to be < scheduler_max_duration
    expect(duration).to be < killer_timeout
    expect(every).to eq(started: [true, true, true], finished: [true, true, true])
  end

  it 'does not shutdown scheduler' do
    current_rss = GetProcessMem.new.bytes.to_i
    puts "rss #{current_rss}"
    scheduler = Rufus::Scheduler.new

    # every 3 seconds do something for 10 seconds with increase RAM by 10MB
    every = { started: [], finished: [] }
    scheduler.every('3') do
      every[:started] << true
      puts 'start: every 3 seconds do something for 10 seconds'
      puts "rss #{GetProcessMem.new.bytes.to_i}"
      sleep 10
      puts 'finish: every 3 seconds do something for 10 seconds'
      every[:finished] << true
    end

    # every 3 seconds check that RAM usage less then 30mb.
    # if not stop scheduler with timeout 10
    limit = current_rss + (30 * one_mb)
    described_class.register(
      scheduler: scheduler,
      frequency: 2,
      timeout: 1,
      min: limit,
      max: limit
    )

    time_before = Time.now.to_i
    scheduler_max_duration = 30
    scheduler.join(scheduler_max_duration)
    duration = Time.now.to_i - time_before

    expect(duration).to be >= scheduler_max_duration
  end
end
