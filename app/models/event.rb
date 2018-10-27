class Event < ApplicationRecord
  has_one :log
  has_many :players, through: :logs # perhaps a player may get injured, and that would result or explain an event.

  #perhaps use this model to save regularized calculations -- goalie-pulled event, after goal? Goal on 1st, 2nd, 3rd shift of the night?

  #maybe instead include all this above in unit-level circumstances

end
