require_relative 'logger'
require_relative 'manager'
require_relative 'job'

module WorkHouse
  class Worker
    include Logger

    attr_accessor :job

    JOB_TIMEOUT = 5

    def initialize(job)
      unless job.class.included_modules.include?(WorkHouse::Job)
        raise ArgumentError.new("'job' must include WorkHouse::Job")
      end
      @job = job
      log "Worker init"
    end

    def log(message)
      super(current_worker, message)
    end

    def timeout
      if @job.timeout
        @job.timeout
      else
        log "No job specific timeout. Using default: #{JOB_TIMEOUT}"
        JOB_TIMEOUT
      end
    end

    def process_job
      log "Beginning work"
      @job.processing!

      Timeout.timeout(self.timeout, JobTimeoutError) do
        @job.perform
      end

      log "Worker done work"
    rescue JobTimeoutError
      job.log_exception($!)
      log "Worker expired: #{$!}..."
    rescue
      job.log_exception($!)
      log "Worker died: #{$!}..."
    ensure
      @job.processed!
      log "Worker done. performed: #{@job.processed?}"
    end

    def self.perform(job)
      worker = self.new(job)
      worker.process_job
    end

    def current_worker
      "Worker (t#{Thread.current[:id]})"
    end
  end
end
