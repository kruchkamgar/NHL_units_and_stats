# requires a team argument

module CreateRecordsFromAPI

  extend CreateUnitsAndInstances
  extend ProcessSpecialEvents
  def create_initial_game_records(date_hash, team:)
  # create a game for each schedule date
    game_id =
    date_hash["games"].first["gamePk"]

    game, teams_hash =
    NHLGameAPI::Adapter
    .new(game_id: game_id)
    .create_game

    rosters = create_rosters(game, teams_hash) # possible to include players

    team_roster =
    rosters.find do |roster|
      roster.team.eql?(team) end

    return [team_roster, game, (rosters - [team_roster]) ]
  end #create_records_per_game

  def create_records_derived_from_events(roster:, team:, game:)
    inserted_events_array =
    NHLGameEventsAPI::Adapter
    .new(team: team, game: game)
    .create_game_events_and_log_entries # *1

    # byebug “¬˚”.,å…πøˆ¨†¥¨ˆ®´  
    if inserted_events_array
      units_groups_hash =
      create_records_from_shifts(
        inserted_events: inserted_events_array,
        roster: roster )

      create_units_and_instances(units_groups_hash, roster: roster)

      process_special_events()
    end
  end

  def create_tallies
    prepared_tallies =
    Unit.joins(:rosters)
    .where(rosters: {team_id: @team.id})
    .group(:id)
    .preload(:instances)
    .preload(:tallies)
    .map do |unit|
      if unit.tallies.empty?
        tally = unit.tallies.build
        tally.tally_instances
        Hash[
          unit_id: unit.id,
          assists: tally.assists,
          plus_minus: tally.plus_minus,
          goals: tally.goals,
          points: tally.points,
          '"TOI"': tally.TOI,
          created_at: Time.now,
          updated_at: Time.now
          # season: @teamseason.season
        ] end # if
    end.compact #map
    unless prepared_tallies.empty?
      SQLOperations.sql_insert_all("tallies", prepared_tallies)
    end
  end #create_tallies


private
        # option: create the main roster
        # NHLRosterAPI::Adapter.new(team.team_id, season: team.season).fetch_roster
  def create_rosters(game, teams_hash)
    teams_data =
    teams_hash
    .map do |side, side_hash|
      [ side_hash["team"]["id"],
        side_hash ] end
    .sort do |a,b|
      a.first <=> b.first end

    team_objects =
    Team.where(team_id: teams_data.transpose.first).order(team_id: :ASC)

    rosters =
    teams_data
    .map.with_index do |team_hashes, i|
      CreateRoster::create_game_roster(
        team_hashes.second, team_objects[i], game ) end
  end

end
