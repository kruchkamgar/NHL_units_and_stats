

module Utilities

  class TimeOperation
    include Utilities
    attr_reader :result

    def initialize (operator, *times)
      @times, @operator = times, operator
      operate
    end

    def operate
      times = @times.map {|time|
        float_(time)
      }

      @seconds_int = times.reverse.inject { |result, time|
        result.send( @operator, time )
      }
      @result = convert
    end

  end # TimeOperation

  def float_ time
    time_hash = time.match(/(?<min>\d+):(?<sec>\d+)/)
    # integer_time = time_hash[:sec].to_f/60*100 + time_hash[:min].to_f

    seconds = time_hash[:sec].to_i + time_hash[:min].to_i*60

    # time = "#{(seconds/60).to_f.floor}:#{seconds%60}"
  end

  def convert
    formatted_time = Time.at(@seconds_int).strftime("%M:%S")
  end

end
