module TestArel

  def basic_sql
    <<~SQL
      SELECT *
      FROM players
      WHERE players.first_name = "Steven"
    SQL
  end

  def retrieve_units_here
    Unit.where("units.id in (#{derived_units_sql.to_sql})") end

  def sql_execute(sql)
    ApplicationRecord.connection.execute(
      sql )
  end

  def team_id; team_id = 1 end
  def position_type; "Forward" end
  def pos_type_mark; 4 end
  def unit_size_mark; 5 end
  def _rel_to_pos_type_mark; [ :gteq, pos_type_mark ] end
  def _rel_to_unit_size_mark; [ :gteq, unit_size_mark ] end

  def team_id_eq
    team_t[:team_id].eq( team_id ) end

  def position_type_eq
    profile_t[:position_type].eq(position_type) if position_type end

  def event_type_eq
    event_t[:event_type].eq('shift') end

  def instance_id_eq
    events_instances_t[:instance_id].eq(instance_t[:id]) end

  def derived_units_sql
    # unit_t
    # .project( Arel.star )

    # .on(instance_t[:unit_id].eq(unit_t[:id]) )
    instance_t
    .project( instance_t[:unit_id] )
    .join( events_instances_t)
      .on( instance_id_eq )
    .join( event_t )
      .on( event_t[:id].eq(events_instances_t[:event_id]) )
    .where( instance_t[:id]
      .in(select_instance_ids
          .join(instance_id_via_count_of_position_type
            .as( Arel.sql("evnts_insts") ))
          .on( Arel::Table.new("evnts_insts")[:instance_id]
            .eq(instance_t[:id]) ))
      .and(event_type_eq) )
    .group( instance_t[:unit_id], events_instances_t[:instance_id] )
    .having( events_instances_t[:instance_id].count
      .send(*_rel_to_unit_size_mark) )
  end

  def select_instance_ids
    instance_t
    .project( instance_t[:id] ) end

  def instance_id_via_count_of_position_type
    events_instances_t
    .project( events_instances_t[:instance_id] )
    .where( events_instances_t[:event_id]
      .in( event_t
          .project( event_t[:id] )
          .where( event_t[:player_id_num]
            .in(select_distinct_player_id_num
                .where(rosters_ids_for_team
                       .and(position_type_eq) ))
            .and( event_type_eq ) ) ))
    .group( events_instances_t[:instance_id] )
    .having( Arel.star.count.send(*_rel_to_pos_type_mark) )
  end

  def select_distinct_player_id_num
    player_t
    .project( player_t[:player_id_num] ).distinct
    .join(players_rosters_t).on(
      players_rosters_t[:player_id].eq(player_t[:id]) )
    .join(player_profiles_t).on(
      player_profiles_t[:player_id].eq(player_t[:id]) ) end

  def rosters_ids_for_team
    players_rosters_t[:roster_id]
      .in( rosters_join_team
        .where( team_id_eq )) end

  def rosters_join_team
    roster_t
    .project( roster_t[:id] )
    .join(team_t).on(
      roster_t[:team_id].eq(team_t[:id]) ) end

  def team_t; Team.arel_table end
  def roster_t; Roster.arel_table end
  def unit_t; Unit.arel_table end
  def profile_t; PlayerProfile.arel_table end
  def players_rosters_t; Arel::Table.new(:players_rosters) end
  def events_instances_t; Arel::Table.new(:events_instances) end
  def event_t; Event.arel_table end
  def instance_t; Instance.arel_table end
  def player_t; Player.arel_table end
  def roster_t; Roster.arel_table end
  def player_profiles_t; PlayerProfile.arel_table end

  def arel_test
    player = Player.arel_table
    player_profile = PlayerProfile.arel_table

    player.project(
      player[:last_name] )
    .where(
      player[:id].in(
        player_profile.project(
          player_profile[:player_id] )
        .where( player_profile[:position_type].eq("Defenseman") )
    ) )
    .where(
      player[:first_name].eq("Steven")
      .and(
        player[:last_name].eq("Santini" ) )
    )
    .to_sql
  end

end

=begin

SELECT instances.unit_id FROM instances
INNER JOIN events_instances ON events_instances.instance_id = instances.id
INNER JOIN events ON events.id = events_instances.event_id
WHERE instances.id IN (
  SELECT instances.id FROM instances
  INNER JOIN (
    SELECT events_instances.instance_id FROM events_instances
    WHERE events_instances.event_id IN (
      SELECT events.id FROM events
      WHERE events.player_id_num IN (
        SELECT DISTINCT players.player_id_num FROM players
        INNER JOIN players_rosters ON players_rosters.player_id = players.id
        INNER JOIN player_profiles ON player_profiles.player_id = players.id
        WHERE players_rosters.roster_id IN (
          SELECT rosters.id FROM rosters
          INNER JOIN teams ON rosters.team_id = teams.id
          WHERE teams.team_id = 1 )
        AND player_profiles.position_type = 'Forward')
      AND events.event_type = 'shift' )
    GROUP BY events_instances.instance_id
    HAVING COUNT(*) >= 3 )
  ON events_instances.instance_id = instances.id)
AND events.event_type = 'shift'
GROUP BY instances.unit_id, events_instances.instance_id
HAVING COUNT(events_instances.instance_id) >= 5
=end

# doesnt work for some reason--
# def distinct_on(field)
#     Arel::Nodes::NamedFunction.new("DISTINCT", field)
# end

# def adjoin_(method, *conditions)
#   if conditions[1].any?
#     adjoin_(
#       method, conditions.first.send(method, conditions[1]),
#         conditions[2..-1] )
#   else
#     conditions.first end
# end
