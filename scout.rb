require 'socket'
require 'json'
require_relative 'agent'

module Scout
    include Agent
    extend self

    @foundResouce = false

    def act(action)
        if action[0] == 'move_scout'
            return move_scout(action[1], action[2], action[3])
        elsif action[0] == 'visit_scout'
            return visit_scout(action[1], action[2], action[3])
        elsif action[0] == 'map_enemy'
            return map_enemy(action[1], action[2], action[3], action[4])
        elsif action[0] == 'map'
            return map(action[1], action[2], action[3], action[4])
        end
    end

    def move_scout(agent, from, to)
        print 'move_scout', ' ', agent, ' ', from, ' ', to, "\n"
        return true
    end

    def visit_scout(agent, from, to)
        print 'visit_scout', ' ', agent, ' ', from, ' ', to, "\n"
        if !@foundResouce
            @@coordinatorServer.puts(JSON.generate({
                :action => 'found_resource',
                :value => [:wood, :forest],
            }))
        end

        @foundResouce = true
        return true
    end

    def map_enemy(agent, resource, enemy, location)
        print 'map_enemy', ' ', agent, ' ', resource, ' ', enemy, ' ', location, "\n"
        return true
    end

    def map(agent, resource, enemy, location)
        print 'map', ' ', agent, ' ', resource, ' ', enemy, ' ', location, "\n"
        return true
    end
end

if $0 == __FILE__
    Scout.run('scout', 2002)
end