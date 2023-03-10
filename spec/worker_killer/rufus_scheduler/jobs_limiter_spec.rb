# frozen_string_literal: true

require 'rufus/scheduler'

RSpec.describe WorkerKiller::RufusScheduler::JobsLimiter do
  it 'shutdowns scheduler after timeout hit' do
    scheduler = Rufus::Scheduler.new

    # every 3 seconds check that RAM usage less then 30mb.
    # if not stop scheduler with timeout 10
    killer_max_count = 5
    killer_timeout = 20
    described_class.register(
      scheduler: scheduler,
      timeout: killer_timeout,
      min: killer_max_count,
      max: killer_max_count,
      verbose: true
    )

    once = { started: [], finished: [] }
    scheduler.in('0') do
      once[:started] << true
      puts 'start: once do something for a 60 seconds'
      sleep 60
      puts 'finish: once do something for a 60 seconds'
      once[:finished] << true
    end
    every3 = { finished: [] }
    scheduler.every('3') do
      puts 'finish: every 3 seconds do something'
      every3[:finished] << true
    end

    time_before = Time.now.to_i
    scheduler_max_duration = 120
    scheduler.join(scheduler_max_duration)
    duration = Time.now.to_i - time_before

    expect(duration).to be < scheduler_max_duration
    # killer_max_count == 5
    # 5 times called every(3) + 1 time called in(0)
    expect(duration).to be >= killer_timeout + 12 # 5 times every(3) = 12 sec because 1st started at 0
    expect(once).to eq(started: [true], finished: [])
    expect(every3[:finished].size).to eq(5)
  end

  it 'shutdowns scheduler before timeout hit' do
    scheduler = Rufus::Scheduler.new

    # every 3 seconds check that RAM usage less then 30mb.
    # if not stop scheduler with timeout 10
    killer_max_count = 5
    killer_timeout = 40
    described_class.register(
      scheduler: scheduler,
      timeout: killer_timeout,
      min: killer_max_count,
      max: killer_max_count,
      verbose: true
    )

    every3 = { started: [], finished: [] }
    scheduler.every('3') do
      every3[:started] << true
      puts 'start: every 3 seconds do something for 5 seconds'
      sleep 5
      puts 'finish: every 3 seconds do something for 5 seconds'
      every3[:finished] << true
    end

    time_before = Time.now.to_i
    scheduler_max_duration = 120
    scheduler.join(scheduler_max_duration)
    duration = Time.now.to_i - time_before

    expect(duration).to be < scheduler_max_duration
    expect(duration).to be < killer_timeout
    # killer_max_count == 5
    # 6 times called every(3)
    expect(duration).to be >= 15 # 6 times every(3) = 12 sec because 1st started at 0
    expect(every3[:finished].size).to eq(6)
    expect(every3[:started].size).to eq(6)
  end

  it 'shutdowns scheduler with job_filter' do
    scheduler = Rufus::Scheduler.new

    # every 3 seconds check that RAM usage less then 30mb.
    # if not stop scheduler with timeout 10
    killer_max_count = 5
    killer_timeout = 40
    described_class.register(
      scheduler: scheduler,
      timeout: killer_timeout,
      min: killer_max_count,
      max: killer_max_count,
      job_filter: ->(job, _) { job.opts[:name] == 'every3' },
      verbose: true
    )

    every2 = { finished: [] }
    # does not counted because of job_filter parameter
    scheduler.every('2', name: 'every2') do
      puts 'finish: every 2 seconds do something'
      every2[:finished] << true
    end
    every3 = { started: [], finished: [] }
    scheduler.every('3', name: 'every3') do
      every3[:started] << true
      puts 'start: every 3 seconds do something for 5 seconds'
      sleep 5
      puts 'finish: every 3 seconds do something for 5 seconds'
      every3[:finished] << true
    end

    time_before = Time.now.to_i
    scheduler_max_duration = 120
    scheduler.join(scheduler_max_duration)
    duration = Time.now.to_i - time_before

    expect(duration).to be < scheduler_max_duration
    expect(duration).to be < killer_timeout
    # killer_max_count == 5
    # 6 times called every(3)
    expect(duration).to be >= 15 # 6 times every(3) = 12 sec because 1st started at 0
    expect(every3[:finished].size).to eq(6)
    expect(every3[:started].size).to eq(6)
    expect(every2[:finished].size).to be_within(1).of(8)
  end
end
