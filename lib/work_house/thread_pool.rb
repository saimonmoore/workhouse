require 'thread'

##
# A pool of threads to which you can schedule jobs
#
# Usage:
#
#   @pool = ThreadPool.new(10)
#   @pool.schedule { puts "do my job" }
#   @pool.shutdown
#
module WorkHouse
  class ThreadPool

    ##
    # Initialize a new ThreadPool
    #
    # @param [Fixnum] Number of threads in the pool
    #
    def initialize(size)
      @jobs = Queue.new

      @pool = Array.new(size) do |i|
        Thread.new do
          Thread.current[:id] = i

          catch(:exit) do
            loop do
              job, args = @jobs.pop
              if job
                job.call(*args)
              end
            end
          end
        end
      end
    end

    ###
    #
    # Schedule a job to be picked up
    # by one of the threads in the pool.
    #
    # @param [Array | Object] args- Any arguments to be passed to the block
    #                               when executed by the thread.
    #
    # @param [Proc] &block Block that thread will executed.
    #                      a.k.a the job to be executed.
    #
    def schedule(*args, &block)
      @jobs << [block, args]
    end

    ##
    # Shutdown the pool.
    #
    # Sends a signal to gracefully terminate all threads
    #
    # Warn: Pool is now empty. To reset create a new ThreadPool
    #
    # @return [Array] Array of threads (Can consult their status)
    #
    def shutdown
      size.times do
        schedule { throw :exit }
      end

      @pool.map(&:join)
    end

    ##
    # Number of threads in the pool
    #
    # @return [Fixnum]
    #
    def size
      Array(threads).length
    end

    ##
    # The threads in the pool
    #
    # @return [Array] of Thread objects
    #
    def threads
      @pool
    end

    ##
    # Queue of jobs to be executed by the Threads
    #
    # @return [Queue]
    #
    def jobs
      @jobs
    end

    ##
    # Id of currently executing thread
    #
    # @return [Fixnum] Index of thread within pool
    #
    def current_thread
      Thread.current[:id]
    end

  end
end
