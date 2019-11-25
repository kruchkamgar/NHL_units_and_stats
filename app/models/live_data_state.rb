
class LiveDataState < ActiveRecord::Base

  def initialize(args)
    super
    @game_id, @start_time = args[:game_id], args[:start_time]
  end

  def cache_element()
    byebug
    Rails.cache.fetch("#{@game_id}/#{@start_time}", expires_in: 12.hours) do
      # ex: do an API request [whose said request may fail to receive a response, at any given time]
      self.attributes
    end
  end


end
