require_relative '../../../lib/work_house/job'
require_relative '../../../lib/work_house/manager'

class WorkHouse::DumbJob
  include WorkHouse::Job

  attr_accessor :performed

  def initialize(name)
    @name = name
  end

  def perform
    super
    sleep 0.1
    @performed = true
  end

  def timeout
    5
  end
end

