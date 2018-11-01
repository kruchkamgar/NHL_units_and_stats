module ApplicationHelper

  def self.creation
    # create team and get its schedule
    @team = NHLTeamAPI::Adapter.new(team_id: 1).create_team
    schedule_hash = NHLTeamAPI::Adapter.new(team_id: 1).fetch_data

    # create a game for each schedule date
    schedule_hash["dates"].each { |date_hash|
      game_id = date_hash["games"].first["gamePk"]

      # game API may deliver two teams' players
      game, teams_hash = NHLGameAPI::Adapter.new(game_id: game_id).create_game
      # create a roster for the team
      NHLRosterAPI::create_game_roster(
        select_team_hash(teams_hash),
        @team, game
      )
      NHLGameEventsAPI::Adapter.new(game_id: game_id).create_game_events
      # byebug
    }

    # create the main roster
    # NHLRosterAPI::Adapter.new(team.team_id, season: team.season).fetch_roster

  end

  # ////////////// helpers /////////////// #

  def self.select_team_hash teams_hash
    teams_hash.select { |side|
      teams_hash[side]["team"]["id"] == @team.team_id
    }.first[1]
  end
end
