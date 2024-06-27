require 'socket'
require 'json'
require_relative 'agent'

module Gatherer
    include Agent
    extend self

    @foundEnemy = false

    def act(action)
        if action[0] == 'pickup'
            return pickup(action[1], action[2])
        elsif action[0] == 'drop'
            return drop(action[1], action[2])
        elsif action[0] == 'move'
            return move(action[1], action[2], action[3])
        end
    end

    def pickup(agent, resource)
        @@environmentServer.puts(JSON.generate({
            :action => 'pickup',
        }))

        if !@@environmentServer.closed?
            resp = @@environmentServer.recvfrom(10000)

            if resp[0] != ''
                message = JSON.parse(resp[0])

                if message['value'] === 'success'
                    print 'pickup', ' ', agent, ' ', resource, "\n"
                    return true
                else
                    print 'Error in action', "\n"

                    if !@foundEnemy
                        @@coordinatorServer.puts(JSON.generate({
                            :action => 'found_enemy',
                            :value => [:enemy, :forest],
                        }))
                        @@coordinatorServer.puts(JSON.generate({
                            :action => 'failed_plan',
                        }))
                    end

                    @foundEnemy = true
                    return false
                end
            end
        end
    end

    def drop(agent, resource)
        print 'drop', ' ', agent, ' ', resource, "\n"
        return true
    end

    def move(agent, from, to)
        print 'move', ' ', agent, ' ', from, ' ', to, "\n"
        return true
    end
end

if $0 == __FILE__
    Gatherer.run('gatherer', 2004)
end