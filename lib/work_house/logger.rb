require_relative 'colorize'

module WorkHouse
  module Logger
    def log(prefix, message, color = (Thread.current[:id].to_i + 1))
      msg = "#{prefix} #{message}"
      puts WorkHouse::Colorize.send(WorkHouse::Colorize::COLORS[color], msg) if ENV["VERBOSE"]
    end
  end
end
