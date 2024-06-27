require 'socket'
require 'json'

module Environment
extend self
    @server = TCPServer.open(2001)
    @hasEnemy = false
    @percentage = nil

    @memory = {
        :scouts => [],
        :gatherers => [],
        :attackers => [],
    }

    def register(agent, client)
        if agent[0] == 'gatherer'
            @memory[:gatherers].push(client)
        elsif agent[0] == 'scout'
            @memory[:scouts].push(client)
        elsif agent[0] == 'attacker'
            @memory[:attackers].push(client)
        end
    end

    def connection()
        loop do
            Thread.start(@server.accept) do |client|
                loop {
                    messageArr = client.recvfrom(10000)
                    messageArr[0].split("\n").each do |messageRaw|
                        message = JSON.parse(messageRaw)
                        print(message, "\n")
                        if message['action'] == 'register'
                            register(message['value'], client)
                            client.puts(JSON.generate({
                                :action => 'response',
                                :value => 'ok'
                            }))
                        elsif message['action'] == 'pickup'
                            pickup(client)
                        elsif message['action'] == 'kill'
                            kill(client)
                        elsif message['action'] == 'finish'
                            client.close
                            exit 0
                        end
                    end
                }
            end
        end
        close()
    end

    def start(percentage)
        @percentage = percentage
        rando = Random.rand()
        if rando <= @percentage
            @hasEnemy = true
        end
    end

    def pickup(client)
        if @hasEnemy
            client.puts(JSON.generate({
                :action => 'response',
                :value => 'error'
            }))
        else
            client.puts(JSON.generate({
                :action => 'response',
                :value => 'success'
            }))
        end
    end

    def kill(client)
        @hasEnemy = false
        client.puts(JSON.generate({
            :action => 'response',
            :value => 'success'
        }))
    end

    def close()
      puts("closed")
      @server.close
    end
end

if $0 == __FILE__
    Environment.start(ARGV[0].to_f)
    Environment.connection()
end