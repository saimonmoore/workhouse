require_relative 'logger'
require_relative 'system_info'
require_relative 'worker'
require_relative 'thread_pool'
require 'timeout'

module WorkHouse
  class JobTimeoutError < StandardError; end

  ##
  #
  # Simple repetative job worker (Note: Not a queue)
  #
  # Usage:
  #
  # jobs = [MyJob.new('a'), MyJob.new('b')]
  # timeout = 5.seconds
  # manager = WorkHouse::Manager.work_on(jobs, timeout)
  #
  # manager.work!
  #
  # Traps INT signal which will stop further job processing and exit.
  #
  # What it does:
  #
  # * Set's up a pool of threads
  # * Takes jobs
  # * For each job, takes a thread and executes the job
  # * Waits for `timeout` time
  # * Repeat until exit.
  #
  class Manager
    extend Logger

    DEFAULT_INTERRUPT = 5 unless defined?(DEFAULT_INTERRUPT) # seconds

    attr_accessor :jobs, :pool, :interrupt, :runs

    Signal.trap('INT') do
      Manager.should_process_jobs = false
      log "Trapped INT..."
      log "No more jobs will be processed"
    end

    at_exit do
      Manager.should_process_jobs = false
      if pool?
        puts "Exiting...shutting down pool..."
        pool.shutdown
      end
    end

    def self.work_on(jobs, interrupt=DEFAULT_INTERRUPT)
      raise ArgumentError.new("Undefined argument: 'interrupt'") unless interrupt

      Manager.should_process_jobs = true
      self.send(:new, jobs, interrupt)
    end

    def initialize(jobs, interrupt)
      @interrupt = interrupt
      @jobs = Array(jobs)
      @runs = 0
      @pool = self.class.pool(pool_size)
    end
    private_class_method :new

    def self.pool?
      !!@pool
    end

    def self.pool(pool_size=nil)
      unless @pool
        puts "Starting thread pool with #{pool_size} threads..."
      end
      @pool ||= WorkHouse::ThreadPool.new(pool_size)
    end

    def self.reset!
      if pool?
        @pool.shutdown
        @pool = nil
      end
    end

    def self.should_process_jobs?
      $should_process_jobs
    end

    def self.should_process_jobs=(bool)
      $should_process_jobs = bool
    end

    def work!
      puts "Processing jobs..."
      puts
      while Manager.should_process_jobs? do
        log "RUN: #{runs}"

        @jobs.each do |job|
          if Manager.should_process_jobs?

            if job.processing?
              log " Job #{job.name} is still processing in run: #{runs} ...skipping..."
              next
            end

            @pool.schedule(job) do |_job|
              log "Job #{_job} started by thread #{Thread.current[:id]}", Thread.current[:id] + 1
              Worker.perform(_job)
              log "Job #{_job} finished by thread #{Thread.current[:id]}", Thread.current[:id] + 1
            end
          else
            log "Stop fetching..."
            log "Exiting...."
            exit
          end
        end

        @interrupt.times do
          if Manager.should_process_jobs?
            Kernel.sleep 1
          else
            log "Interrupting sleep"
            return
          end
        end
        @runs += 1
        log "Next tick..."
      end
    end

    private

    def pool_size
      [processors, @jobs.length.divmod(processors).reduce(:+)].max
    end

    def processors
      SystemInfo.processor_count
    end

    def self.log(message, color=0)
      super("", message, color)
    end

    def log(message, color=0)
      self.class.log(message, color)
    end
  end
end

##
# Example usage
##
if $0 == __FILE__

  require_relative 'job'

  class FetchIncomingEmailJob
    include WorkHouse::Job

    def initialize(name)
      @name = name
    end

    def timeout
      5
    end

    def perform
      emails_to_process = Array.new(rand(7).to_i, 'a')
      how_long = rand(10).to_i

      log "Processing #{emails_to_process.length} emails...."
      emails_to_process.each_with_index do |email, i|
        email = "#{email}_#{i}"
        if should_process?
          log "processing: #{email}"

          if (rand(10) == 0)
            raise "Boom! Worker died"
          end

          Kernel.sleep(how_long)
          log "processed: #{email}"
        else
          log "Exiting subjob processing loop"
          exit
        end
      end
    end
  end

  projects = %w(a b c d e).map do |p|
    FetchIncomingEmailJob.new(p)
  end

  WorkHouse::Manager.work_on(projects, 3).work!

end
