

module Utilities

  class TimeOperation
    include Utilities # access to Utilities methods
    attr_reader :minutes, :seconds

    def initialize (
      operator = nil, times,
      seconds: nil, minutes: nil )

      @times, @operator, @seconds, @minutes =
      times, operator, seconds, minutes

      control_flow() # translate OR operate?
    end

    def control_flow
      if @minutes || @seconds then
        @seconds = translate(@seconds, @minutes) else @seconds = 0 end
      if @times
        operate() end
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

      # use the first hash in arguments, for [and as the] #original_format
      @special_format_hash = @times[special_formats_indices[0]] if special_formats_indices.any?

      times_in_seconds =
      @times
      .map.with_index do |time, index|
        if special_formats_indices.include?(index)
          std = standardize_formats(time)
        elsif time.class == Integer
          time
        else
          # merge into standardize_formats
          date_string_to_string_array(time)
        end
      end.flatten
      # run the time operation, output to @minutes, @seconds ...
      inject_to_instance(times_in_seconds)
    end

  def result; format_to_time_notation() end
  def original_format; special_format() end

  end # TimeOperation

  # ////////////// helpers ////////////// #

  def format_to_time_notation
    s = @seconds
    if @seconds > 3600
      formatted_time = "%02d:%02d:%02d" % [s / 3600 % 24, s / 60 % 60, s % 60]
    else
      "%02d:%02d" % [s / 60 % 60, s % 60]
      # Time.at(@seconds).strftime("%M:%S")
    end
  end

  # allow format parameter beyond this default, for multiple-type operations
  def special_format()
    s = @seconds
    case @special_format_hash[:format]
    when 'yyyymmdd_hhmmss', 'hhmmss'
      base = @special_format_hash[:time][/.+_/]
      formatted_time = "%s%02d:%02d:%02d" % [base, s / 3600 % 24, s / 60 % 60, s % 60]
      # else
      #   base = @special_format_hash[:time][/(?<=_\d{2}).+/]
      #   formatted_time = "%s%02d:%02d" % [base, s / 60 % 60, s % 60]
        # Time.at(@seconds).strftime("%M:%S")
      # end
    when "TZ"
    when "Nhl_time_stamp"
      time_stamp_format = "%04d%02d%02d_%02d%02d%02d" % @special_format_hash[:time]
    end # case
  end

  def string_array_to_seconds(string_array)
    # if string_array[0].class != Array
    #   array = [string_array].flatten(1)[0] else array = string_array end
    array = string_array[0]
    case array.size
    when 0..6
      hours, minutes, seconds = array[-3].to_i, array[-2].to_i, array[-1].to_i
      seconds += minutes * 60 + hours * 3600
    end
  end

  # merge into standardize_formats
  def date_string_to_string_array(times)
    times = [times].flatten
    matches =
    times
    .map do |time|
      # return time, if already in seconds
      # if time.class == Integer then next time end
      if time.count(":") == 2
        matches = time.match(/(?<hrs>\d+):(?<min>\d+):(?<sec>\d+)/)
      else
        matches = time.match(/(?<min>\d+):(?<sec>\d+)/) end
    end # map
    string_array_to_seconds(matches)
  end

  # total the times array
  def inject_to_instance(times)
    @seconds += times.inject { |result, time|
      result.send( @operator, time )
    }
    @minutes = @seconds/60.0
  end

  # ////////////// process special formats ////////////// #

  # rename process_formats and roll-in default: #date_string_to_string_array
  def standardize_formats(special_formats)
    times = [special_formats].flatten
    matches =
    times
    .map do |time|
      if time.class != Hash
        # default time format
      end

      case time[:format]
      when "yyyymmdd_hhmmss", "hhmmss"
        hhmmss =
        /(\d{2})(\d{2})(\d{2})(?=$)/
        .match(time[:time])
      when "TZ"
        scan = time[:time].scan(/\d+/)
      end
    end #map
    string_array_to_seconds(matches)
  end

  def date_string_to_array(string)
    gsub = string.gsub(/\D/, ',')[0..-3]

    gsub_to_a = gsub.split(',')
  end

end
