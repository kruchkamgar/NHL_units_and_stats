module Test

  $game_id = 2017020019
  @team = Team.find_by_id(1)

  if ($game = Game.find_by_game_id($game_id))
    @roster = $game.rosters.first
  end

  def create_units
    CreateUnitsAndInstances.get_lines_from_shifts(@team, @roster, $game)
  end

      def process_special_events
        CreateUnitsAndInstances.process_special_events(@team, @roster, $game)
      end

  def create_game_roster
    @team, team_adapter = NHLTeamAPI::Adapter.new(team_id: 1).create_team
    schedule_hash = team_adapter.fetch_data

    # create a game for each schedule date
    date_hash = schedule_hash["dates"].first
    game_id = date_hash["games"].first["gamePk"]
      unless game_id then byebug end

      # note: game API could deliver two teams' players
      game, teams_hash = NHLGameAPI::Adapter.new(game_id: $game_id).create_game

      # create a roster for the team
      roster = CreateRoster::create_game_roster(
        ApplicationHelper.select_team_hash(teams_hash, @team.team_id),
        @team, game
      )
  end

  def create_game_events

    events = NHLGameEventsAPI::Adapter.new(team:
      @team, game: $game, roster: @roster).create_game_events
  end

  module_function :create_units, :process_special_events, :create_game_roster, :create_game_events

end

# unit_array = Unit.all.map {|unit| [unit.instances.count, *unit.instances.map{|inst| inst.events.count}]}

# unit_ = Unit.all.map {|unit| if unit.instances.map{|inst| inst.events.count}.first == 4 then [unit.instances.first.events[0..-1].map(&:player_profiles).map {|p| p[0].player.last_name }, unit.instances.count, unit.instances.first.events.count] end}.compact

# Unit.all[-100].instances.first.events[0..-1].map(&:player_profiles).map {|p| p[0].player.last_name }
