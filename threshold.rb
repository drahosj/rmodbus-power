#! /usr/bin/env
require 'rmodbus'
include ModBus

c = TCPClient.new('127.0.0.1', 1500 +  ARGV[0].to_i)
c.with_slave(1) do |s|
  puts "Threshold was #{s.read_holding_registers(0, 1)[0]}"
  puts "Setting to #{ARGV[1]}"
  s.write_holding_register(0, ARGV[1].to_i)
end
