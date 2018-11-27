

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


  # ////////////// helpers ////////////// #

  def convert
    formatted_time = Time.at(@seconds_int).strftime("%M:%S")
  end

  def float_ time
    time_hash = time.match(/(?<min>\d+):(?<sec>\d+)/)

    seconds = time_hash[:sec].to_i + time_hash[:min].to_i*60
  end

end
