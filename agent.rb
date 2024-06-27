module Agent
    extend self

    @@coordinatorHost = 'localhost'
    @@coordinatorPort = 2000
    @@coordinatorServer = TCPSocket.open(@@coordinatorHost, @@coordinatorPort)

    @@environmentHost = 'localhost'
    @@environmentPort = 2001
    @@environmentServer = TCPSocket.open(@@environmentHost, @@environmentPort)

    @@server = nil
    @@starting = true
    @@hasPlan = false
    @@plan = []

    def run(name, port)
        loop {
            receiveMsgs()
            if @@starting
                start(name, port)
            elsif @@hasPlan
                if @@plan.length > 0
                    action = @@plan.shift()
                    result = act(action)
                    if !result
                        @@plan.unshift(action)
                    end
                else
                    puts "finished"
                    @@hasPlan = false
                    @@coordinatorServer.puts(JSON.generate({
                        :action => 'finished_plan',
                    }))
                end
            end
        }
    end


    def start(name, port)
        @@coordinatorServer.puts(JSON.generate({
            :action => 'register',
            :value => [name, port]
        }))

        @@environmentServer.puts(JSON.generate({
            :action => 'register',
            :value => [name, port]
        }))
        @@environmentServer.recvfrom(10000)

        @@server = TCPServer.open(port)
        @@starting = false
    end

    def receiveMsgs()
        if IO.select([@@coordinatorServer], nil, nil, 0.5) && (messageArr = @@coordinatorServer.recvfrom(10000))
            messageArr[0].split("\n").each do |messageRaw|
                message = JSON.parse(messageRaw)
                if message['action'] == 'plan'
                    puts "Receiving plan"
                    @@plan = message['value']
                    @@hasPlan = true
                elsif message['action'] == 'cancel'
                    puts "Canceling plan"
                    @@plan = []
                    @@hasPlan = false
                elsif message['action'] == 'finish'
                    puts "Finishing"
                    @@coordinatorServer.puts(JSON.generate({
                        :action => 'close',
                    }))
                    @@coordinatorServer.close
                    @@environmentServer.close
                    @@server.close
                    exit 0
                end
            end
        end
    #     Thread.new do
    #         loop {
    #             messageArr = @@coordinatorServer.recvfrom(10000)
    #             messageArr[0].split("\n").each do |messageRaw|
    #                 message = JSON.parse(messageRaw)
    #                 puts message
    #                 if message['action'] == 'plan'
    #                     puts "Receiving plan"
    #                     @@plan = message['value']
    #                     @@hasPlan = true
    #                 elsif message['action'] == 'cancel'
    #                     @@plan = []
    #                     @@hasPlan = false
    #                 elsif message['action'] == 'finish'
    #                     exit 0
    #                 end
    #             end
    #         }
    #     end
    end
end