#\ -o 0.0.0.0 -p 9292
path = File.expand_path "../", __FILE__

require 'rubygems'
require 'sinatra'
require "#{path}/main"

run Sinatra::Application
