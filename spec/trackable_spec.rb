# encoding: utf-8

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
dir = File.dirname(__FILE__)

require "geocaching"
require "#{dir}/helper"

if ENV["GC_TRACKABLE_TYPES"]
  types = ENV["GC_TRACKABLE_TYPES"].split
else
  types = Geocaching::TrackableType::TYPES.to_a.map { |a| a[0].to_s }
end

types.each do |type|
  begin
    require "#{dir}/trackable/#{type}"
  rescue LoadError
    $stderr.puts "Missing test for trackable type #{type}"
  end
end