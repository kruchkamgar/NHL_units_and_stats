class LogEntry < ApplicationRecord
  belongs_to :player_profile, optional: true
  belongs_to :event
end
