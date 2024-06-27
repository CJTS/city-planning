require 'subprocess'
require 'benchmark'
require 'benchmark-memory'

def runExperiments(replan, percentage)
    success = 0
    percentageNumber = percentage.to_f * 100

    threadEnvironment = Thread.new do |t|
        Subprocess.check_call(["ruby", "environment.rb", percentage], { :stdout => Subprocess::PIPE })
    end
    sleep(0.5)

    threadCoordinator = Thread.new do |t|
        Subprocess.check_call(["ruby", "coordinator.rb", replan], { :stdout => 'a.out' })
        lines = File.read('a.out')
        if lines.include?("SUCCESS")
            success = 1
        elsif lines.include?("REPLANED")
            success = 2
        elsif lines.include?("FAILURE")
            success = 3
        end
    end
    sleep(0.5)

    threadGatherer = Thread.new do |t|
        Subprocess.check_call(["ruby", "gatherer.rb"], { :stdout => Subprocess::PIPE })
    end
    sleep(0.5)

    threadAttacker = Thread.new do |t|
        Subprocess.check_call(["ruby", "attacker.rb"], { :stdout => Subprocess::PIPE })
    end
    sleep(0.5)

    threadScout = Thread.new do |t|
        Subprocess.check_call(["ruby", "scout.rb"], { :stdout => Subprocess::PIPE })
    end
    sleep(0.5)

    threadCoordinator.join()
    return success
end

resultsTrue10 = []
resultsFalse10 = []
resultsTrue30 = []
resultsFalse30 = []
resultsTrue50 = []
resultsFalse50 = []
resultsTrue70 = []
resultsFalse70 = []
resultsTrue100 = []
resultsFalse100 = []

resultsTimeTrue10 = []
resultsTimeFalse10 = []
resultsTimeTrue30 = []
resultsTimeFalse30 = []
resultsTimeTrue50 = []
resultsTimeFalse50 = []
resultsTimeTrue70 = []
resultsTimeFalse70 = []
resultsTimeTrue100 = []
resultsTimeFalse100 = []

executions = 30

benchmarkResult = Benchmark.bm do |benchmark|
    executions.times do
        sleep(0.5)
        result = benchmark.report { resultsTrue10.push(runExperiments("true", "0.1")) }
        resultsTimeTrue10.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsFalse10.push(runExperiments("false", "0.1")) }
        resultsTimeFalse10.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsTrue30.push(runExperiments("true", "0.3")) }
        resultsTimeTrue30.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsFalse30.push(runExperiments("false", "0.3")) }
        resultsTimeFalse30.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsTrue50.push(runExperiments("true", "0.5")) }
        resultsTimeTrue50.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsFalse50.push(runExperiments("false", "0.5")) }
        resultsTimeFalse50.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsTrue70.push(runExperiments("true", "0.7")) }
        resultsTimeTrue70.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsFalse70.push(runExperiments("false", "0.7")) }
        resultsTimeFalse70.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsTrue100.push(runExperiments("true", "1")) }
        resultsTimeTrue100.push(result.real - 2.5)

        sleep(0.5)
        result = benchmark.report { resultsFalse100.push(runExperiments("false", "1")) }
        resultsTimeFalse100.push(result.real - 2.5)
    end
end

puts "Results:"

print('true', "\n")
[
    [resultsTrue10,resultsTimeTrue10],
    [resultsTrue30,resultsTimeTrue30],
    [resultsTrue50,resultsTimeTrue50],
    [resultsTrue70, resultsTimeTrue70],
    [resultsTrue100,resultsTimeTrue100]
].each do |arrs|
    executions.times do |index|
        print(arrs[0][index], ' ', arrs[1][index], "\n")
    end
    print("\n")
end

print('false', "\n")
[
    [resultsFalse10,resultsTimeFalse10],
    [resultsFalse30,resultsTimeFalse30],
    [resultsFalse50,resultsTimeFalse50],
    [resultsFalse70, resultsTimeFalse70],
    [resultsFalse100,resultsTimeFalse100]
].each do |arrs|
    executions.times do |index|
        print(arrs[0][index], ' ', arrs[1][index], "\n")
    end
    print("\n")
end