class Event < ApplicationRecord
  belongs_to :game
  has_and_belongs_to_many :instances
  has_many :log_entries
  has_many :player_profiles, through: :log_entries # perhaps a player may get injured, and that would result or explain an event.

  #perhaps use this model (edit: or log_entries) to save regularized calculations -- goalie-pulled event, after goal? Goal on 1st, 2nd, 3rd shift of the night?

  #maybe instead include all this above in unit-level circumstances

  API =
  Hash[
    start_time: "startTime",
    end_time: "endTime",
    player_id_num: "playerId",
    period: "period",
    event_type: "eventDescription"
  ]

end
