require_relative 'spec_helper'
require_relative '../lib/work_house/job'
require_relative 'support/work_house/dumb_job'

class AnImplementedJob < WorkHouse::DumbJob; end
class AnUnimplementedJob
  include WorkHouse::Job
end
class JobWithoutTimeout < WorkHouse::DumbJob
  def timeout
    nil
  end
end

describe WorkHouse::Worker do
  subject { WorkHouse::Job }

  let(:implemented_job) { AnImplementedJob.new('foo') }
  let(:unimplemented_job) { AnUnimplementedJob.new('foo') }
  let(:job_without_timeout) { JobWithoutTimeout.new('foo') }

  describe "#perform" do
    it "should raise an ArgumentError if no 'name' attribute is present" do
      expect {
        unimplemented_job.perform
      }.to raise_error(ArgumentError)
    end

    it "should not raise an ArgumentError if the 'name' attribute is present" do
      expect {
        implemented_job.perform
      }.to_not raise_error
    end

    it "should raise an ArgumentError if the 'timeout' method is not present" do
      expect {
        job_without_timeout.perform
      }.to raise_error
    end
  end

  describe "#to_s" do
    it "should raise an ArgumentError if no 'name' attribute is present" do
      expect {
        unimplemented_job.to_s
      }.to raise_error(ArgumentError)
    end

    it "should not raise an ArgumentError if the 'name' attribute is present" do
      expect {
        implemented_job.to_s
      }.to_not raise_error
    end

    it "should return the name attribute" do
      implemented_job.to_s.should == 'foo'
    end
  end

  describe "#processing!" do
    it "should mark job as being processed" do
      implemented_job.processing!
      implemented_job.should be_processing
    end

    it "should not mark job as having been processed" do
      implemented_job.processing!
      implemented_job.should_not be_processed
    end
  end

  describe "#processed!" do
    it "should mark job as having been processed" do
      implemented_job.processed!
      implemented_job.should be_processed
    end

    it "should not mark job as being processed" do
      implemented_job.processed!
      implemented_job.should_not be_processing
    end
  end

  describe "#should_process?" do
    before :each do
      WorkHouse::Manager.stub(:should_process_jobs?).and_return(true)
    end

    it "delegates to WorkHouse::Manager::should_process_jobs?" do
      WorkHouse::Manager.should_receive(:should_process_jobs?).and_return(true)

      implemented_job.should_process?
    end
  end

  describe "::should_process?" do
    before :each do
      WorkHouse::Manager.stub(:should_process_jobs?).and_return(true)
    end

    it "delegates to WorkHouse::Manager::should_process_jobs?" do
      WorkHouse::Manager.should_receive(:should_process_jobs?).and_return(true)

      implemented_job.class.should_process?
    end
  end
end

