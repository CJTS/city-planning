require 'socket'
require 'json'
require_relative 'agent'

module Attacker
    include Agent
    extend self

    def act(action)
        if action[0] == 'move_attacker'
            return move_attacker(action[1], action[2])
        elsif action[0] == 'kill'
            return kill(action[1], action[2], action[3])
        end
    end

    def move_attacker(agent, location)
        print 'move_attacker', ' ', agent, ' ', location, "\n"
        return true
    end

    def kill(agent, enemy, location)
        print 'kill', ' ', agent, ' ', enemy, ' ', location, "\n"
        @@environmentServer.puts(JSON.generate({
            :action => 'kill',
        }))
        return true;
    end
end

if $0 == __FILE__
    Attacker.run('attacker', 2003)
end