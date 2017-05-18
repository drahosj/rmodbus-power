#! /usr/bin/env ruby
require 'rmodbus'
include ModBus

line1 = ModBus::TCPClient.new('127.0.0.1', 1501)
line2 = ModBus::TCPClient.new('127.0.0.1', 1502)
line3 = ModBus::TCPClient.new('127.0.0.1', 1503)
line4 = ModBus::TCPClient.new('127.0.0.1', 1504)
line5 = ModBus::TCPClient.new('127.0.0.1', 1505)
line6 = ModBus::TCPClient.new('127.0.0.1', 1506)

lines = [line1, line2, line3, line4, line5, line6]

# Set thresholds
lines.each do |line|
  line.with_slave(1) do |s|
    s.write_holding_register(0, 10)
  end
end

# Monitor and perform protection
while true do
  lines.each do |line|
    line.with_slave(1) do |s|
      if (s.read_coils(0, 1)[0] == 1)
        if s.read_input_registers(0, 1)[0] > s.read_holding_registers(0, 1)[0]
          s.write_coil(0, 0)
        end
      end
    end
  end
  sleep 1
end
