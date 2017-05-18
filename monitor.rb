#! /usr/bin/env ruby
require 'rmodbus'
include ModBus

lines = [1501, 1502, 1503, 1504, 1505, 1506]

lines.each_with_index do |port, i|
  c = TCPClient.new('127.0.0.1', port)
  c.with_slave(1) do |slave|
    state = slave.read_coils(0, 1)[0] == 1 ? "CLOSED" : "OPEN"
    #warn = slave.read_discrete_inputs(0,1)[0] == 1 ? "!!TEMP!!" : ""
    warn = ""
    temp = slave.read_input_registers(0,1)[0]
    thresh = slave.read_holding_registers(0,1)[0]
    puts "Line #{i + 1}: #{state} Temp: #{temp}/#{thresh} #{warn}"
  end
end
