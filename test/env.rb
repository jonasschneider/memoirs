require 'test/unit'

require "rubygems"
require "bundler/setup"

require 'memoirs'

require 'rack/test'
require "vcr"

VCR.config do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.stub_with :webmock # or :fakeweb
end