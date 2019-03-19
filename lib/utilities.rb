

module Utilities

  class TimeOperation
    include Utilities # access to Utilities methods
    attr_reader :result, :minutes, :seconds

    def initialize (operator = nil, *times, seconds: nil, minutes: nil)
      @times, @operator, @seconds, @minutes = times, operator, seconds, minutes
      operate()
    end

    def operate
      times = @times.map { |time|
        float_(time) }

      if @minutes
        @seconds = @minutes*60
      else
        # seconds of type Integer
        @seconds = times.inject { |result, time|
          result.send( @operator, time )
        }
        @minutes = @seconds/60.0 end

      @result = convert_to_time_notation()
    end

  end # TimeOperation


  # ////////////// helpers ////////////// #

  def convert_to_time_notation
    formatted_time = Time.at(@seconds).strftime("%M:%S")
  end

  def float_ time
    time_hash = time.match(/(?<min>\d+):(?<sec>\d+)/)

    seconds = time_hash[:sec].to_i + time_hash[:min].to_i*60
  end

end
