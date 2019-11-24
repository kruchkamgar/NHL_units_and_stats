
require 'sidekiq-scheduler'

class ScheduleLiveData
  include Sidekiq::Worker

  include Utilities

  def perform(coming_schedule_dates, ts_instance)
    coming_schedule_dates_hash = coming_schedule_dates.second;

    inst_hash = ts_instance;
    # find the dates that fall in the next three days
    next_three_dates =
    coming_schedule_dates_hash
    .select do |date|
      game_date = date["games"].first["gameDate"]
      game_date_time = Time.utc( *date_string_to_array(game_date) )
      coming_within_three_days =
      ( Time.now.utc() + (84600)*3 > # three days, in seconds
        game_date_time &&
        game_date_time > Time.now.utc() ) end


    # call method to schedule init
    next_three_dates
    .each do |date_hash|
      byebug
      ReadNHLApis::TeamSeason.schedule_live_data_init(date_hash, inst_hash) end
    # live_data = fetch(url_and_instance.first)

  end

end
