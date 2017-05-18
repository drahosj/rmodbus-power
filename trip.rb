#!/usr/bin/env ruby
require 'rmodbus'
include ModBus

c = TCPClient.new('127.0.0.1', 1500 + ARGV[0].to_i)
c.with_slave(1) {|s| s.write_coil(0, 0)}
