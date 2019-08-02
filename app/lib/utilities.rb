

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
        to_seconds(time) }

      if @minutes
        @seconds = @minutes*60
      else
        # total the times array
        @seconds = times.inject { |result, time|
          result.send( @operator, time )
        }
        @minutes = @seconds/60.0 end

      @result = convert_to_time_notation()
    end

  end # TimeOperation

  # ////////////// helpers ////////////// #

  def convert_to_time_notation
    s = @seconds
    if @seconds > 3600
      formatted_time = "%02d:%02d:%02d" % [s / 3600, s / 60 % 60, s % 60]
    else
      "%02d:%02d" % [s / 60 % 60, s % 60]
      # Time.at(@seconds).strftime("%M:%S")
    end
  end

  def to_seconds(time)
    if time.count(":") == 2
      time_hash = time.match(/(?<hrs>\d+):(?<min>\d+):(?<sec>\d+)/)
    else
      time_hash = time.match(/(?<min>\d+):(?<sec>\d+)/) end

    seconds =
    time_hash[:sec].to_i +
    time_hash[:min].to_i*60

    if time_hash.to_a.size > 3
      seconds += time_hash[:hrs].to_i*3600
    else seconds end
  end


  # ////////////// Time class conversions ////////////// #

  def date_string_to_array(string)
    gsub = string.gsub(/\D/, ',')[0..-3]

    gsub_to_a = gsub.split(',')
  end

end
