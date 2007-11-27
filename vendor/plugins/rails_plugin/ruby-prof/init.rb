require 'profiling'

# Grab log path from current rails configuration
ActionController::Profiling::LOG_PATH = File.expand_path(File.dirname(config.log_path))

if true
    ActionController::Base.class_eval do
      include ActionController::Profiling
    end
end
