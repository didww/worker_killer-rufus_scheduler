# frozen_string_literal: true

require 'rufus/scheduler'

RSpec.describe WorkerKiller::RufusScheduler::OOMLimiter do
  let(:one_mb) { 1024**2 }
  let(:current_rss) { GetProcessMem.new.bytes.to_i }

  before do
    @store = []
    puts "rss #{current_rss}"
  end

  # easy way to increase RAM in test
  def increase_ram(bytes)
    @store << ('a' * bytes)
  end

  it 'shutdowns scheduler after timeout hit' do
    scheduler = Rufus::Scheduler.new

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

    # once do something for a minute
    once = { started: [], finished: [] }
    scheduler.schedule_in('0') do
      once[:started] << true
      puts 'start: once do something for a 60 seconds'
      sleep 60
      puts 'finish: once do something for a 60 seconds'
      once[:finished] << true
    end
    every3 = { started: [], finished: [] }
    scheduler.every('3') do
      every3[:started] << true
      puts 'start: every 3 seconds do something for 10 seconds with increase RAM by 11MB'
      increase_ram(11 * one_mb)
      puts "rss #{GetProcessMem.new.bytes.to_i}"
      sleep 10
      puts 'finish: every 3 seconds do something for 10 seconds with increase RAM by 11MB'
      every3[:finished] << true
    end

    time_before = Time.now.to_i
    scheduler_max_duration = 120
    scheduler.join(scheduler_max_duration)
    duration = Time.now.to_i - time_before

    expect(duration).to be < scheduler_max_duration
    expect(duration).to be > killer_timeout
    expect(once[:started].size).to eq(1)
    expect(once[:finished].size).to eq(0)
    expect(every3[:started].size).to eq(3)
    expect(every3[:finished].size).to eq(3)
  end

  it 'shutdowns scheduler before timeout hit' do
    scheduler = Rufus::Scheduler.new

    # every 3 seconds do something for 10 seconds with increase RAM by 10MB
    every3 = { started: [], finished: [] }
    scheduler.every('3') do
      every3[:started] << true
      puts 'start: every 3 seconds do something for 10 seconds with increase RAM by 11MB'
      increase_ram(11 * one_mb)
      puts "rss #{GetProcessMem.new.bytes.to_i}"
      sleep 10
      puts 'finish: every 3 seconds do something for 10 seconds with increase RAM by 11MB'
      every3[:finished] << true
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
    expect(every3[:started].size).to eq(3)
    expect(every3[:finished].size).to eq(3)
  end

  it 'does not shutdown scheduler' do
    scheduler = Rufus::Scheduler.new

    # every 3 seconds do something for 10 seconds with increase RAM by 10MB
    every3 = { started: [], finished: [] }
    scheduler.every('3') do
      every3[:started] << true
      puts 'start: every 3 seconds do something for 10 seconds'
      puts "rss #{GetProcessMem.new.bytes.to_i}"
      sleep 10
      puts 'finish: every 3 seconds do something for 10 seconds'
      every3[:finished] << true
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
    expect(every3[:started].size).to be >= 6
    expect(every3[:finished].size).to be >= 6
  end
end
