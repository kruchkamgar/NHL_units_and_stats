module ComposedQueries

  # def set_inst_variables
  #   @team_id = 1
  #   @position_type = "Forward"
  #   @position_type_mark = 3
  #   @unit_size_mark = 5
  # end

  def retrieve_units_rows_by_param()
    # Unit.where( unit_t[:id].in(derived_units_sql).to_sql )
    ApplicationRecord.connection.execute(
      derived_units_sql.to_sql )
  end

  def team_id; @team_id end
  def position_type; @position_type end
  def pos_type_mark; @position_type_mark end
  def unit_size_mark; @unit_size_mark end
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
    unit_t
    .project( unit_t[:id], player_t[:player_id_num] )
    .join( alias_(unit_ids_filter, :unit_ids_filter) )
      .on( Arel::Table.new(:unit_ids_filter)[:unit_id].eq(unit_t[:id]) )
    .join(instance_t).on(instance_t[:unit_id].eq(unit_t[:id]) )
    .join( events_instances_t )
      .on( events_instances_t[:instance_id].eq(instance_t[:id]) )
    .join( event_t )
      .on( event_t[:id].eq(events_instances_t[:event_id]) )
    .join( player_t )
      .on( player_t[:player_id_num].eq(event_t[:player_id_num]) )
    .join( player_profiles_t)
      .on( player_profiles_t[:player_id].eq(player_t[:id]) )
    .where( event_type_eq
      .and(position_type_eq) )
    .group( unit_t[:id], player_t[:player_id_num] )
  end

    # .on(instance_t[:unit_id].eq(unit_t[:id]) )
  def unit_ids_filter
    instance_t
    .project( instance_t[:unit_id] )
    .join( events_instances_t)
      .on( instance_id_eq )
    .join( event_t )
      .on( event_t[:id].eq(events_instances_t[:event_id]) )
    .where( events_instances_t[:instance_id]
      .in( instance_id_via_count_of_position_type )
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
      .in(event_t
          .project( event_t[:id] )
          .where( event_t[:player_id_num]
            .in(select_distinct_player_id_num()
                .where(rosters_ids_for_team()
                       .and(position_type_eq) ))
            .and(event_type_eq) )))
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
      .in( rosters_join_team()
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

  def alias_(table, name)
    Arel::Nodes::As.new( table, Arel::Table.new(name) ) end

end

=begin

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


# .as( "evnts_insts" ))
# .on( Arel::Table.new("evnts_insts")[:instance_id]
# .eq(instance_t[:id]) ))
