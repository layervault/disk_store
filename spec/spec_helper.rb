require File.expand_path './lib/disk_store'
require 'rspec'
require 'vcr'

VCR.configure do |c|
  c.configure_rspec_metadata!

  c.default_cassette_options = {
    serialize_with:              :json,
    preserve_exact_body_bytes:   true,
    decode_compressed_response:  true,
    match_requests_on:          [:method]
  }

  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.ignore_localhost = true
end

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].gsub(/\//, "_").split(/\s+/, 2).join("/").gsub(/[^\w\/]+/, "_").downcase
    VCR.use_cassette(name) { example.call }
  end
end