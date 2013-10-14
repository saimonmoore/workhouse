require_relative 'spec_helper'
require_relative '../lib/work_house/worker'
require_relative 'support/work_house/dumb_job'

class SomeOtherJob < WorkHouse::DumbJob; end

describe WorkHouse::Worker do
  subject { WorkHouse::Worker }

  let(:job) { SomeOtherJob.new('foo') }


  context "when initializing" do
    it "should accept a job argument" do
      expect {
        subject.new(job)
      }.not_to raise_error
    end

    it "should raise an ArgumentError with the job argument" do
      expect {
        subject.new
      }.to raise_error(ArgumentError)
    end

    it "should raise an ArgumentError if the job argument does not include WorkHouse::Job" do
      expect {
        subject.new("foo")
      }.to raise_error(ArgumentError)
    end
  end

  context "#perform" do
    let!(:worker) { WorkHouse::Worker.new(job) }

    before :each do
      subject.stub(:new).and_return(worker)
    end

    it "should instantiate a new worker instance with the job" do
      subject.should_receive(:new).with(job).and_return(worker)
      subject.perform(job)
    end
  end

  context "when processing a job" do
    let(:worker) { subject.new(job) }

    it "should call #perform on the job" do
      job.should_receive(:perform)

      worker.process_job
    end

    it "should mark the job as being processed during processing" do
      job.should_receive(:processing!)
      worker.process_job
    end

    it "should mark the job as having been processed after it's processed" do
      job.should_receive(:processed!)
      worker.process_job
    end

    it "should log a Timeout::Error on the job if job takes too long to perform" do
      job.stub(:perform).and_raise(Timeout::Error)
      job.should_receive(:log_exception).with(an_instance_of(Timeout::Error))
      worker.process_job
    end

    it "should log any exception on the job if the job raises an exception while being processed." do
      job.stub(:perform).and_raise(StandardError)
      job.should_receive(:log_exception).with(an_instance_of(StandardError))
      worker.process_job
    end
  end
end

