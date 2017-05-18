#! /usr/bin/env ruby
require 'rmodbus'

# Power grid simulator
#
# Suitable for a CDC
#
###############
# Architecture
#
# Each line consists of a Modbus TCP server
# acting as a breaker. The TCP server has a coil representing
# circuit CLOSED (1) or OPEN (0). The server also has a 
# input register for temperature, and a holding register
# for shutdown threshold. There is a discrete input representing over-
# temperature condition (temp > threshold).
#
#
#                  LOAD1
#                    O
#                    |
#                    |
#                  LINE2
#                    |
#                    |
#                    O----LINE3----O
# GEN1 O----LINE1----O             O----LINE5----O LOAD2
#                    O----LINE4----O
#                                  O
#                                  |
#                                  |
#                                LINE6
#                                  |
#                                  |
#                                  O
#                                LOAD3
#
###############
# Simulation
# Each tick, power flow will be simulated. Tempetarure is a function
# of power flow and past temperature.

class Line
  attr_accessor :power
  attr_reader :max_power

  def initialize modbus, max
    @modbus = modbus
    @modbus.holding_registers = [0]
    @modbus.input_registers = [0]
    @modbus.coils = [1]
    @modbus.discrete_inputs = [over_temp?]
    @modbus.start

    @power = 0
    @max_power = max
  end

  def closed?
    not @modbus.coils[0].zero?
  end

  def over_temp?
    @modbus.input_registers[0] > @modbus.holding_registers[0]
  end

  def update
    @modbus.discrete_inputs[0] = over_temp?

    temp = @modbus.input_registers[0]
    if (@power > @max_power)
      temp += 1
    else
      temp -= 1
    end
    temp = 0 if temp < 0

    @modbus.input_registers[0] = temp
  end
end

class Gen
  attr_accessor :capacity
  attr_accessor :usage
  
  def initialize cap
    @capacity = cap
    @usage = 0
  end
end

class Load
  attr_accessor :load
  attr_accessor :supplied

  def initialize load
    @load = load
    @supplied = 0
  end
end

class Simulator
  def initialize
    @line1 = Line.new ModBus::TCPServer.new(1501), 120
    @line2 = Line.new ModBus::TCPServer.new(1502), 30
    @line3 = Line.new ModBus::TCPServer.new(1503), 60
    @line4 = Line.new ModBus::TCPServer.new(1504), 60
    @line5 = Line.new ModBus::TCPServer.new(1505), 75
    @line6 = Line.new ModBus::TCPServer.new(1506), 75

    @lines = [@line1, @line2, @line3, @line4, @line5, @line6]

    @load1 = Load.new(20)
    @load2 = Load.new(40)
    @load3 = Load.new(50)

    @loads = [@load1, @load2, @load3]

    @gen1 = Gen.new(200)
    
    @gens = [@gen1]
  end

  def print_state
    @lines.each_with_index do |line, i|
      puts "Line #{i + 1}: #{line.power}/#{line.max_power}"
    end
    @loads.each_with_index do |load, i|
      puts "Load #{i + 1}: #{load.supplied}/#{load.load}"
    end
    @gens.each_with_index do |gen, i|
      puts "Generator #{i + 1}: #{gen.usage}/#{gen.capacity}"
    end
  end

  def calc_power_flow
    @lines.each do |line|
      line.power = 0
    end

    @loads.each do |load|
      load.supplied = 0
    end

    @gens.each do |gen|
      gen.usage = 0
    end

    # This logic is hardcoded for now
    # Load 1
    if @line1.closed? and @line2.closed?
      @line1.power += @load1.load
      @line2.power += @load1.load

      @load1.supplied = @load1.load
      @gen1.usage += @load1.load
    end

    # Load 2
    if @line5.closed? and (@line3.closed? or @line4.closed?) and @line1.closed?
      @line1.power += @load2.load
      @line5.power += @load2.load
      if (@line3.closed? and @line4.closed?)
        @line3.power += @load2.load / 2
        @line4.power += @load2.load / 2
      elsif (@line3.closed? and not @line4.closed?)
        @line3.power += @load2.load
      elsif (@line4.closed? and not @line3.closed?)
        @line4.power += @load2.load
      end
      @load2.supplied = @load2.load
      @gen1.usage += @load2.load
    end

    # Load 3
    if @line6.closed? and (@line3.closed? or @line4.closed?) and @line1.closed?
      @line1.power += @load3.load
      @line6.power += @load3.load
      if (@line3.closed? and @line4.closed?)
        @line3.power += @load3.load / 2
        @line4.power += @load3.load / 2
      elsif (@line3.closed? and not @line4.closed?)
        @line3.power += @load3.load
      elsif (@line4.closed? and not @line3.closed?)
        @line4.power += @load3.load
      end
      @load3.supplied = @load3.load
      @gen1.usage += @load3.load
    end

    @lines.each do |line|
      line.update
    end
  end
end

sim = Simulator.new
while true do
  sim.calc_power_flow
  sim.print_state
  sleep(1)
end
