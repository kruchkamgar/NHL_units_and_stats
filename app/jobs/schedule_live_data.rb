
class ScheduleLiveData
  queue_as :schedule_live_data

include Utilities

  def perform(coming_schedule_dates, ts_instance)
    coming_schedule_dates = args[:coming_schedule_dates]; instance = args[:instance];
    # find the dates that fall in the next three days
    next_three_dates =
    coming_schedule_dates
    .select do |date|
      game_date = date["games"]["gameDate"]
      game_date_time = Time.utc( *date_string_to_array(game_date) )
      coming_within_three_days? =
      ( Time.now.utc() + (84600)*3 > # three days, in seconds
        game_date_time &&
        game_date_time > Time.now.utc() ) end

    # call method to schedule init
    coming_schedule_dates
    .each do |date|
      ReadApisNHL::schedule_live_data_init(date_hash, instance) end
    # live_data = fetch(url_and_instance.first)

  end

end
