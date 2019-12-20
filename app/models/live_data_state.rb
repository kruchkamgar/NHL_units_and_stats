
# could just use file(s) in tmp folder, instead
class LiveDataState
  attr_accessor :game_id, :time_stamp, :plays, :on_ice

  def initialize(args)
    @game_id, @time_stamp, @on_ice_plus, @plays, @on_ice_diff = args[:game_id], args[:time_stamp], args[:on_ice_plus], args[:plays], args[:on_ice_diff]
  end

  def cache_element()

    Rails.cache.fetch("#{@game_id}/#{@time_stamp}", expires_in: 12.hours) do
      # ex: do an API request [whose said request may fail to receive a response, at any given time]
      self.as_json
    end
  end


end
