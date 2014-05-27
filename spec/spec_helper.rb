require File.expand_path './lib/disk_store'
require 'rspec'
require 'securerandom'
require 'tempfile'
require 'tmpdir'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true

  config.treat_symbols_as_metadata_keys_with_true_values = true
end