class LogEntry < ApplicationRecord
  belongs_to :player_profile
  belongs_to :event
end
