

module Utilities

  class TimeOperation
    include Utilities # access to Utilities methods
    attr_reader :result, :minutes, :seconds

    def initialize (
      operator = nil, *times,
      seconds: nil, minutes: nil )

      @times, @operator, @seconds, @minutes =
      times, operator, seconds, minutes

      control_flow() # translate OR operate?
    end

    def control_flow
      if @minutes || @seconds then
        @seconds = translate(@seconds, @minutes)
      else operate() end
    end

    def translate(seconds, minutes)
      if seconds
        seconds += minutes*60
      else seconds = minutes * 60 end
    end

    def operate
      # Hash in arguments?
      special_formats_indices =
      @times.each_index
      .select do |index|
        @times[index].class == Hash end

      times_in_seconds =
      @times
      .map.with_index do |time, index|
        if special_formats_indices.include?(index)
          standardize_formats(time)
        elsif time.class == Integer
          time
        else to_seconds(time) end
      end.flatten
      # run the time operation, output to @minutes, @seconds ...
      inject_to_instance(times_in_seconds)
      @result = format_to_time_notation()
    end

  end # TimeOperation

  # ////////////// helpers ////////////// #

  def format_to_time_notation
    s = @seconds
    if @seconds > 3600
      formatted_time = "%02d:%02d:%02d" % [s / 3600, s / 60 % 60, s % 60]
    else
      "%02d:%02d" % [s / 60 % 60, s % 60]
      # Time.at(@seconds).strftime("%M:%S")
    end
  end

  def to_seconds(times)
    times
    .map do |time|
      # return time, if already in seconds
      # if time.class == Integer then next time end

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
    end # map
  end

  # total the times array
  def inject_to_instance(times)
    @seconds = times.inject { |result, time|
      result.send( @operator, time )
    }
    @minutes = @seconds/60.0
  end

  # ////////////// process special formats ////////////// #

  def standardize_formats(special_formats)
    times = [special_formats].flatten
    times
    .map do |time|
      case time[:format]
      when "yyyymmdd_hhmmss", "hhmmss"
        mmss =
        /(\d{2})(\d{2})(?=$)/
        .match(time[:time])
        minutes, seconds = mmss[1].to_i, mmss[2].to_i
        seconds += minutes * 60
      end
    end #map
  end

  def date_string_to_array(string)
    gsub = string.gsub(/\D/, ',')[0..-3]

    gsub_to_a = gsub.split(',')
  end

end
