require 'rails_helper'

RSpec.describe Polling::Scheduler, type: :model do
  let(:scheduler) { Polling::Scheduler.new }

  after :each do
    scheduler.rufus_scheduler.shutdown
  end
  
  let(:greetings) { 'hello verify self service...' }
  let(:worker) {
   Class.new do
      def work
      end
   end.new
  }
  let(:display) {
    Class.new do
      def name(name)
        "my name is #{name}"
      end
    end.new
  }
  context 'is polling (every)' do
    it 'creates a new scheduler' do
      expect(scheduler).not_to be_nil
    end

    it 'has chainable methods' do
      expect(scheduler.mode(:every)).to eql scheduler
      expect(scheduler.perform(->{ worker.work })).to be scheduler
    end

    it 'does something when mode is bad' do
      expect(scheduler.mode(:ofather)).to eql scheduler
      expect(scheduler.perform(->{ worker.work })).not_to be scheduler
    end

    it 'uses duration string to poll on a repeatable schedule' do
      scheduler.mode(:every, '1h')
              .perform(->{ display.name('Fido dido')})
      job = scheduler.job

      expect(job.class).to eql(Rufus::Scheduler::EveryJob)
      expect(job).to be_scheduled
      expect(job.frequency).to eq(3600.0)
      expect(scheduler.action_result).to eql display.name('Fido dido')
    end

    it 'polls when there is an action but until test is not given' do
      scheduler.mode(:every, '2m')
              .perform(->{ greetings })

      job = scheduler.job
      expect(job).to be_scheduled
      expect(job.frequency).to eq(120)
      expect(scheduler.action_result).to eql greetings
    end

    it 'does not poll when there is an action but until test is true' do
      scheduler.mode(:every, '2m')
               .perform(->{ 'hello verify self service...' })
               .until(scheduler.action_result.present?)

      job = scheduler.job

      expect(job).not_to be_scheduled
      expect(scheduler.action_result).to eql greetings
    end

    it 'can display errors when timeout is specified' do
      scheduler = Polling::Scheduler.new(timeout: '0.5s')
      scheduler.mode(:every, '1s')
               .perform(-> {
                 sleep 0.9
                })

        sleep(2)
        expect(scheduler.stderr.string).to match(/Rufus::Scheduler::TimeoutError/)
    end

    it 'can display errors when timeout is specified' do
      scheduler = Polling::Scheduler.new(timeout: '0.5s')
      scheduler.mode(:every, '1s')
               .perform(-> {
                 sleep 0.9
                })

        sleep(2)
        expect(scheduler.stderr.string).to match(/Rufus::Scheduler::TimeoutError/)
    end

    context 'stops using last:/last_in/:last_at/times: options' do
      it 'uses a time instance to unschedule job at a particular time' do
        counter = 0
        t = Time.now + 2.seconds
        tt = nil
        scheduler = Polling::Scheduler.new(last: t)
        job = scheduler.mode(:every, '0.5s')
                .perform(-> {
                  display.name('Fido dido')
                  counter += 1
                  tt = Time.now}
                  )
                  .job
        sleep 3

        expect(job.last_at.to_f).to eql(t.to_f)
        expect([3, 4]).to include(counter)
        expect(scheduler.rufus_scheduler.jobs).not_to include(job)
        expect(scheduler.job).not_to be_scheduled
      end

      it 'uses a duration string to unschedule job after a particular duration' do
        t = Time.now
        scheduler = Polling::Scheduler.new(last_in: '2s')
        job = scheduler.mode(:every, '0.5s')
                      .perform
                      .job

        expect(job.last_at).to be >= t + 2.seconds
        expect(job.last_at).to be < t + 2.5.seconds
      end

      it 'uses no of times to unschedule job' do
        counter = 0
        scheduler = Polling::Scheduler.new(times: 3)
        job = scheduler.mode(:every, '0.5s')
                        .perform(-> { counter += 1 })
                        .job

        expect(job).to be_scheduled
        sleep(2.6)

        expect(counter).to eq(3)
        expect(job).not_to be_scheduled
      end
    end
  end

  it 'can create and use multiple scheduler instances' do
    scheduler.mode(:every, '2m')
    .perform(->{ greetings })

    job = scheduler.job
    expect(job).to be_scheduled
    expect(job.frequency).to eq(120)
    expect(scheduler.action_result).to eql greetings

    scheduler_one = Polling::Scheduler.new
    scheduler_one.mode(:every, '2m')
    .perform(->{ 'hello verify self service...' })
    .until(scheduler_one.action_result.present?)

    job_one = scheduler_one.job

    expect(job_one).not_to be_scheduled
    expect(scheduler_one.action_result).to eql greetings

    scheduler_two = Polling::Scheduler.new
    scheduler_two.mode(:every, '1h')
    .perform(->{ display.name('Fido dido')})
    job_two = scheduler_two.job

    expect(job_two.class).to eql(Rufus::Scheduler::EveryJob)
    expect(job_two).to be_scheduled
    expect(job_two.frequency).to eq(3600.0)
    expect(scheduler_two.action_result).to eql display.name('Fido dido')
  end

  context 'is scheduling (in)' do
    it 'creates an in job schedule' do
      expect(scheduler.mode(:in)).to eql scheduler
      expect(scheduler.perform(->{ worker.work })).to be scheduler
    end
    it 'uses duration string to schedule an action' do
      job = scheduler.mode(:in, '1h')
                     .perform(->{ display.name('Fido dido')})
                     .job

      expect(job.class).to eql(Rufus::Scheduler::InJob)
      expect(job).to be_scheduled
      expect(scheduler.action_result).to eql display.name('Fido dido')
    end
  end
end
