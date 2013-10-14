require 'active_support/concern'

require_relative 'logger'
require_relative 'manager'
require 'thread'

module WorkHouse
  module Job
    include Logger
    extend ActiveSupport::Concern

    attr_accessor :name, :processed, :processing

    module ClassMethods
      def should_process?
        Manager.should_process_jobs?
      end
    end

    ##
    # Recommended for subclasses to call #super
    #
    def perform
      require_name
      require_timeout
    end

    def should_process?
      self.class.should_process?
    end

    def processed?
      @processed
    end

    def processing?
      @processing
    end

    def processed!
      @processed = true
      @processing = false
    end

    def processing!
      @processed = false
      @processing = true
    end

    def log(message)
      super(current_job, message)
    end

    def log_exception(error)
      log(" logging exception: #{error} (#{error.class}) ")
    end

    def to_s
      require_name
      require_timeout
      name
    end

    private

    def current_job
      "Job (t#{Thread.current[:id]}) [#{self.class.name}: #{self.name}]"
    end

    def require_name
      unless name
        raise ArgumentError.new("WorkHouse::Jobs require a 'name' attribute")
      end
    end

    def require_timeout
      unless timeout
        raise ArgumentError.new("WorkHouse::Jobs require a 'timeout' method (return Fixnum seconds)")
      end
    end
  end
end
