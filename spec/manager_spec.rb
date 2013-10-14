require_relative 'spec_helper'
require_relative '../lib/work_house/manager'
require_relative '../lib/work_house/job'
require_relative '../lib/work_house/system_info'
require_relative 'support/work_house/dumb_job'

class SomeJob < WorkHouse::DumbJob
  def perform
    sleep 0.1
    @performed = true

    # Force exit of the job queue once all jobs processed
    if name.to_i == 2
      WorkHouse::Manager.should_process_jobs = false
    end
  end
end

describe WorkHouse::Manager do
  subject { WorkHouse::Manager }

  let(:jobs) { [1,2] }

  before :each do
    WorkHouse::SystemInfo.stub(:processor_count).and_return(2)
  end

  context "when initialising" do

    after :each do
      subject.reset!
    end

    it "should not allow initializing via ::new" do
      expect {
        subject.new(jobs, 5)
      }.to raise_error(NoMethodError)
    end

    it "should allow initializing via ::work_on" do
      expect {
        subject.work_on(jobs, 5)
      }.to_not raise_error
    end

    it "should require an array of jobs" do
      expect {
        subject.work_on
      }.to raise_error(ArgumentError)
    end

    it "should default to the DEFAULT_INTERRUPT constant if the interrupt argument is not specified" do
      expect {
        subject.work_on([])
      }.to_not raise_error(ArgumentError)
    end

    it "should require a number indicating time to interrupt long-running jobs" do
      expect {
        subject.work_on([], nil)
      }.to raise_error(ArgumentError)
    end

    context "should initialise the pool" do
      context "when processor count is greater than sum of quotient and remainder of number of jobs divided by processor count" do
        before :each do
          subject.any_instance.stub(:processors).and_return(4)
          @manager = subject.work_on(jobs, 5)
        end

        it "to the number of processor cores" do
          @manager.pool.size.should == 4
        end
      end
      context "when processor count is less than sum of quotient and remainder of number of jobs divided by processor count" do
        before :each do
          subject.any_instance.stub(:processors).and_return(1)
          @manager = subject.work_on(jobs, 2)
        end

        it "to the sum of the quotient and remainder" do
          @manager.pool.size.should == 2
        end
      end
    end

    it "should allow processing of jobs" do
      subject.work_on(jobs, 5)
      subject.should_process_jobs?.should == true
    end
  end

  context "when processing jobs" do
    let(:few_jobs) { 3.times.map {|i| SomeJob.new("#{i}"); } }

    it "schedules all jobs with the thread pool" do
      manager = subject.work_on(few_jobs, 5)

      manager.work!

      few_jobs.all? do |job|
        job.performed.should be_true
      end

      manager.runs.should == 1
    end
  end

  context "#processors (private api)" do
    before :each do
      WorkHouse::SystemInfo.stub(:processor_count).and_return(2)
    end

    it "should delegate to WorkHouse::SystemInfo::processor_count" do
      manager = subject.work_on(jobs, 5)
      WorkHouse::SystemInfo.should_receive(:processor_count).and_return(2)
      manager.send(:processors)
    end
  end
end
