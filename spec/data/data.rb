require_relative './seed_team_hashes.rb'
require_relative './seed_events_hashes.rb'

include SeedTeamHashes
 def team_hash
   team_hash_devils()
 end

 def team_hash_02
   team_hash_islanders()
 end

 def get_team_hash
   this = fetch_team_hash()["teams"]
   # .find do |side|
   #   side.second["team"]["name"] == @team.name end
   # .second
 end

include SeedEventsHashes

  def events_hashes
    events_hashes_instance_data()
  end

  def events_hashes_legacy
    events_hashes_2017020019()
  end

  def events_hashes_penalties
    events_hashes_2018021020_penalties()
  end
