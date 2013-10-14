require 'rspec'

# Requires support files
Dir[Pathname.pwd.join("support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
end

alias :running :lambda
