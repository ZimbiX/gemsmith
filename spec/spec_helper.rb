require "bundler/setup"

if ENV["CODECLIMATE_REPO_TOKEN"]
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

require "gemsmith"
require "gemsmith/cli"
require "pry"
require "pry-byebug"
require "pry-state"
require "pry-stack_explorer"
require "pry-remote"
require "pry-rescue"

Dir[File.join(File.dirname(__FILE__), "support/kit/**/*.rb")].each { |file| require file }
Dir[File.join(File.dirname(__FILE__), "support/shared_examples/**/*.rb")].each { |file| require file }

# Uncomment to add a custom configuration. For the default configuration, see the "support/kit" folder.
# RSpec.configure do |config|
# end
