
class LiveDataState
  attr_accessor :game_id, :start_time

  # def team; @team end
  # def game_id; @game_id end
  # def start_time; @start_time end

  def initialize(game_id:, start_time:)
    @game_id, @start_time = game_id, start_time end

  def cache_element()
    Rails.cache.fetch("#{@game_id}/#{@start_time}", expires_in: 12.hours) do
      # ex: do an API request [whose said request may fail to receive a response, at any given time]
      self
    end
  end


end
