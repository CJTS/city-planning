require 'socket'
require 'json'
require 'timeout'
timeout_in_seconds = 10

require_relative './HyperTensioN/Hypertension'
require_relative 'domain.hddl'

# Predicates
SCOUT = [
  :scout
]
LOCATION = [
  :base,
  :forest,
  :mine
]
ON = 0
VISITED = 1
GATHERER = [
  :gatherer
]
ENEMY = [
  :enemy
]
RESOURCE = [
  :wood,
  :gold
]
EXIST = 2
EMPTY = 3
ATTACKER = [
  :attacker
]
HAVE = 4

module Coordinator
  include Hypertension
  extend self

  @starting = true
  @server = TCPServer.open(2000)
  @replan = false
  @startReplanning = false

  @startedGathering = false
  @finishedGathering = false

  @environmentHost = 'localhost'
  @environmentPort = 2001
  @environmentServer = TCPSocket.open(@environmentHost, @environmentPort)

  @memory = {
    :scouts => [],
    :gatherers => [],
    :attackers => [],
    :locations => [:forest, :mine],
    :freeAttacker => 0,
    :woodSources => [],
    :goldSources => [],
    :threats => [],
    :missions => []
  }

  @state = [
    [
      [:gatherer, :base],
      [:scout, :base],
      [:attacker, :base]
    ],
    [],
    [
      # [:wood, :forest]
    ],
    [
      :gatherer
    ],
    [],
  ] # ON

  @tasks = []

  @plan = nil
  @planCount = 0

  def connection()
    loop do
      Thread.start(@server.accept) do |client|
        loop {
          messageArr = client.recvfrom(10000)
          messageArr[0].split("\n").each do |messageRaw|
            message = JSON.parse(messageRaw)
            puts message
            if message['action'] == 'register'
              register(message['value'], client)
            elsif message['action'] == 'found_resource'
              registerResource(message['value'])
            elsif message['action'] == 'found_enemy'
              registerEnemy(message['value'])
            elsif message['action'] == 'finished_plan'
              finished_plan()
            elsif message['action'] == 'failed_plan'
              failed_plan()
            end

            if message['action'] == 'close'
              client.close
              exit 0
            else
              client.puts(JSON.generate({
                :action => 'response',
                :value => 'ok'
              }))
            end
          end
        }
      end
    end
    close()
  end

  def run(replan)
    @replan = replan === 'true'

    loop do
      if @starting && @memory[:gatherers].length > 0 && @memory[:scouts].length > 0 && @memory[:attackers].length > 0
        @starting = false
      elsif !@starting && !@plan && @planCount == 0 && !@startedGathering
        @memory[:missions].each do |client|
          puts client
          client[:busy] = false
          client[:conn].puts(JSON.generate({
            :action => 'cancel',
          }))
        end

        @plan = solve()

        scout = @plan.select {|item| item.include?(:scout)}
        gatherer = @plan.select {|item| item.include?(:gatherer)}
        attacker = @plan.select {|item| item.include?(:attacker)}

        if scout.length > 0
          msg = JSON.generate({
            :action => 'plan',
            :value => scout
          })
          client = @memory[:scouts].detect {|e| !e[:busy]}
          if client
            client[:busy] = true
            client[:conn].puts(msg)
            @planCount = @planCount + 1;
            @memory[:missions].push(client)
          end
        end

        if gatherer.length > 0
          msg = JSON.generate({
            :action => 'plan',
            :value => gatherer
          })
          client = @memory[:gatherers].detect {|e| !e[:busy]}
          if client
            client[:busy] = true
            client[:conn].puts(msg)
            @planCount = @planCount + 1;
            @memory[:missions].push(client)
          end
        end

        if attacker.length > 0
          msg = JSON.generate({
            :action => 'plan',
            :value => attacker
          })
          client = @memory[:attackers].detect {|e| !e[:busy]}
          if client
            client[:busy] = true
            client[:conn].puts(msg)
            @planCount = @planCount + 1;
            @memory[:missions].push(client)
          end
        end
      elsif !@starting && @startedGathering && @finishedGathering # finished starting, doesn't have plan, no one working, gathered something
        finish()
        break
      end
    end
  end

  def register(agent, client)
    if agent[0] == 'gatherer'
      @memory[:gatherers].push({ :conn => client, :busy => false})
    elsif agent[0] == 'scout'
      @memory[:scouts].push({ :conn => client, :busy => false})
    elsif agent[0] == 'attacker'
      @memory[:attackers].push({ :conn => client, :busy => false})
    end
  end

  def registerResource(resourceInfo)
    if(resourceInfo[0] == 'wood')
      @state[2].push([:wood, :forest])
    end
  end

  def registerEnemy(resourceInfo)
    if resourceInfo[0] == 'enemy' && !@state[2].include?([:enemy, :forest])
      @state[2].push([:enemy, :forest])
      @startReplanning = true
    end
  end

  def finished_plan()
    @planCount = @planCount - 1;
    if @planCount == 0
      puts('finished')
      @memory[:missions].each do |client|
        client[:busy] = false
      end
      @plan = nil

      if @startedGathering
        @finishedGathering = true
      end
    end
  end

  def failed_plan()
    if @replan && @startReplanning
      puts 'PUTA QUE ME PARIU CARALHO'
      @startedGathering = false
      @planCount = 0
      @plan = nil
    elsif !@replan
      finish()
      exit 0
    end
  end

  def solve()
    if(@state[2].length > 0)
      # Gather
      @tasks = [[:grow, :gatherer, :scout, :attacker]]
      @startedGathering = true
      Basic.problem(@state, @tasks)
    else
      @tasks = []
      @memory[:locations].each { |location| @tasks.push([:visit, :scout]) }
      Basic.problem(@state, @tasks)
    end
  end

  def finish()
    @memory[:scouts].each do |client|
      client[:conn].puts(JSON.generate({
        :action => 'finish',
      }))
    end
    @memory[:gatherers].each do |client|
      client[:conn].puts(JSON.generate({
        :action => 'finish',
      }))
    end
    @memory[:attackers].each do |client|
      client[:conn].puts(JSON.generate({
        :action => 'finish',
      }))
    end

    @environmentServer.puts(JSON.generate({
      :action => 'finish',
    }))
    @environmentServer.close
  end

  def success()
    if @finishedGathering && !@startReplanning
      puts "SUCCESS"
    elsif @finishedGathering && @startReplanning
      puts "REPLANED"
    else
      puts "FAILURE"
    end
  end

  def close()
    puts("closed")
    @server.close
  end
end

if $0 == __FILE__
  thr = Thread.new { Coordinator.connection() }

  begin
    Timeout::timeout(timeout_in_seconds) do
      Coordinator.run(ARGV[0])
      Coordinator.success()
    end
  rescue Timeout::Error
    Coordinator.finish()
    puts "FAILURE"
  end
end