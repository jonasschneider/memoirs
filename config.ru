#\ -s puma

require "rubygems"
require "bundler/setup"

$:.unshift '.'
require 'memoirs'

run App
