# requires a team argument

module CreateRecordsFromAPI

  extend CreateUnitsAndInstances
  extend ProcessSpecialEvents
  def create_initial_game_records(date_hash, team:) # only needs team hash here––
  # create a game for each schedule date
    game_id =
    date_hash["games"].first["gamePk"]

    game, teams_hash =
    NHLGameApi::Adapter
    .new(game_id: game_id)
    .create_game

    team_roster, opposing_roster = create_rosters(game, teams_hash, team) # possible to include players

    return [team_roster, game, opposing_roster ]
  end #create_records_per_game

  def create_records_derived_from_events(roster:, team:, game:)
    inserted_events_array =
    NHLGameEventsApi::Adapter
    .new(team: team, game: game)
    .create_game_events_and_log_entries # *1

    # byebug
    if inserted_events_array
      units_groups_hash =
      form_units_from_shifts(
        inserted_events: inserted_events_array,
        roster: roster )

      create_units_instances_etc(units_groups_hash, roster: roster)

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
  def create_rosters(game, teams_hash, team)
    teams_data =
    teams_hash
    .map do |side, side_hash|
      [ side_hash["team"]["id"],
        side_hash,
        side,
        side["team"]["name"]
        side["team"]["name"] == team.name ] end
    .sort do |a,b|
      a.first <=> b.first end

    # find and pass appopriate Team object
    team_objects =
    Team.where(
# call it team_id_num?
      team_id: teams_data.transpose.first)
    .order(team_id: :ASC)

    created_rosters =
    teams_data
    .map.with_index do |team_hashes, i|
      Hash[
        roster: CreateRoster::create_game_roster(
          team_hashes.second, team_objects[i], game ),
        side: team_hashes.third,
        team_name: team_hashes.fourth
        team: team_hashes.fifth ]
    end

    team_roster = created_rosters.find do |roster| roster[:team] end
    opponent_roster = created_rosters.find do |roster| !roster[:team] end
    return [ team_roster, opponent_roster ]
  end

end
