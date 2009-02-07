# config.ru
# This is a simple config.ru file for running a Merb app with Passenger at DreamHost
# It should be installed in the root directory of your Merb app
# It has been tested with Merb 1.0.7 and Ruby 1.8.7

$:.unshift("/usr/local/lib/site_ruby/1.8/")
$:.unshift("/usr/lib/ruby/1.8/")

ENV['GEM_PATH'] = '/home/dcparker/.gem/' # your local gem home

require 'rubygems'
  Gem.clear_paths
  Gem.path.unshift(ENV['GEM_PATH'])
gem 'merb-core', '1.0.7.1'
require 'merb-core'

Merb::Config.setup(:merb_root => File.expand_path(File.dirname(__FILE__)),
                   :environment => ENV['RACK_ENV'])
Merb.environment = Merb::Config[:environment]
Merb.root = Merb::Config[:merb_root]
Merb::BootLoader.run

run Merb::Rack::Application.new
