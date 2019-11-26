
class LiveDataState
  attr_accessor :game_id, :time_stamp, :plays

  def initialize(args)
    @game_id, @time_stamp, @plays, @onIce = args[:game_id], args[:time_stamp], args[:plays]
  end

  def cache_element()

    Rails.cache.fetch("#{@game_id}/#{@time_stamp}", expires_in: 12.hours) do
      # ex: do an API request [whose said request may fail to receive a response, at any given time]
      byebug
      self.as_json
    end
  end


end
