require_relative './test_team_hashes.rb'
require_relative './test_events_hashes.rb'

include TestTeamHashes
 def team_hash
   team_hash_devils()
 end

 def team_hash_02
   team_hash_islanders()
 end

include TestEventsHashes
  def events_hashes
    events_hashes_2017020019()
  end

  def events_hashes_penalties
    events_hashes_2018021020_penalties()
  end
