module ComposedQueries
  # include TestComposedQueries

  def set_inst_variables
    @team_id = 4
    @position_type = "Forward"
    @position_type_mark = 3
    @unit_size_mark = 5
  end


  def instances_by_roster_and_game(game_record_id, players_ids)
    # instance_t.project(instance_t[Arel.star]).distinct
    Instance.joins(
      instance_t.join(events_instances_t).on( events_instances_t[:instance_id].eq(instance_t[:id]) ).join_sources,
      events_instances_t.join(event_t).on(
        event_t[:id].eq(events_instances_t[:event_id]) ).join_sources )
    .where(
      event_t[:player_id_num].in(players_ids)
      .and(event_type_eq_shift)
      .and( event_t[:game_id].eq(game_record_id) ))
    .distinct
  end

  def games_by_team_shifts(*columns, team_id)
    query =
    games_w_rtrs(*columns).distinct
    .join(players_rosters_t).on(
      players_rosters_t[:roster_id].eq(roster_t[:id])  )
    .join(player_t).on(
      player_t[:id].eq(players_rosters_t[:player_id]) )
    .join(player_profile_t).on(
      player_profile_t[:player_id].eq(player_t[:id]) )
    .join(log_entry_t).on(
      log_entry_t[:player_profile_id].eq(player_profile_t[:id]) )
    .join(event_t)
      .on( event_t[:id].eq(log_entry_t[:event_id])
      .and( event_t[:game_id].eq(game_t[:id]) ))
    .where( roster_t[:team_id].eq(team_id)
      .and( event_type_eq_shift ) )
    .order( game_t[:game_id].desc )
  end

  def evts_evt_typ_eq
    event_t
    .project( event_t[:event_type] )
    .where( event_type_eq_shift )
  end

  def games_w_rtrs(*columns)
    game_t
    .project( *columns.map do |col| game_t[col] end )
    .join(games_rosters_t).on(
      games_rosters_t[:game_id].eq(game_t[:id]) )
    .join(roster_t).on(
      roster_t[:id].eq(games_rosters_t[:roster_id]) )
  end



  # /////////////  units queries  ////////////// #

  def retrieve_units_rows_by_param()
    # Unit.where( unit_t[:id].in(derived_units_sql).to_sql )
    ApplicationRecord.connection.execute(
      derived_units_sql.to_sql )
  end

  def retrieve_units_rows_by_param_optimized()
    ApplicationRecord.connection.execute(
      derived_units_with_pids.to_sql )
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
    player_profile_t[:position_type].eq(position_type) if position_type end

  def event_type_eq_shift
    event_t[:event_type].eq('shift') end

  def instance_id_eq
    events_instances_t[:instance_id].eq(instance_t[:id]) end

# /////////////  derived units, via units > circumstances > player_profiles > players  ///////////// #

  # porformance: adding a view instead of the cte
  def create_cir_pro_join_view
    Arel.sql("CREATE VIEW cir_pro_join_view").as(
    '(' + unit_joins_cir_pprfl.to_sql + ')' )
  end

  # join units to player_profiles, through circumstances

  def cte_cir_pro_t
    Arel::Table.new(:u_cir_pro) end

  def cte_cir_pro
    Arel.sql("u_cir_pro").as(
      '(' + unit_joins_cir_pprfl.to_sql + ')' )
      # Arel.sql("u_cir_pro AS (#{unit_joins_cir_pprfl.to_sql})")
  end #add .WITH at end of queries which incorporate this

  def u_cir_pro_t; Arel::Table.new(:u_cir_pro) end

  # join player_profiles via circumstances
  def unit_joins_cir_pprfl
    unit_t
    .project( unit_t[:id].as('uid'), player_profile_t[:player_id].as('ppr_id'), player_profile_t[:position_type].as('ppr_pos') )
    .join( circumstance_t )
      .on( circumstance_t[:unit_id].eq(unit_t[:id]) )
    .join( player_profile_t)
      .on( player_profile_t[:id].eq(circumstance_t[:player_profile_id]) ) # one profile, per player on a unit
  end

  def unit_where_pos_eq()

    unit_t
    .project(unit_t[:id].as('uid'))
    .join( alias_(unit_joins_cir_pprfl, :u_cir_pro) )  #alias would work w/o using .with(cte)
      .on( u_cir_pro_t[:uid].eq(unit_t[:id]) )
    .where( u_cir_pro_t[:ppr_pos].eq(position_type) )

  end

  def unit_where_pos_eq_and_count()
    unit_where_pos_eq()
    .group(unit_t[:id])
    .having( unit_t[:id].count.send(*_rel_to_pos_type_mark) )
  end

  def u_rstr_tm
    unit_t
    .project( unit_t[:id] ).distinct
    .join( rosters_units_t )
      .on( rosters_units_t[:unit_id].eq(unit_t[:id]) )
    .join( roster_t )
       .on( roster_t[:id].eq(rosters_units_t[:roster_id]) )
    .join( team_t )
      .on( team_t[:id].eq(roster_t[:team_id]) )
    .where( team_t[:team_id].eq(team_id) )
  end

  def u_cir_prfl_plyr

    unit_t
    .project(unit_t[:id])
    .join( alias_(unit_joins_cir_pprfl, :u_cir_pro) )
      .on( u_cir_pro_t[:uid].eq(unit_t[:id]) )  # join player_profiles [to group & count]
    .join( alias_( u_rstr_tm, :units_by_team ) )
      .on( Arel::Table.new(:units_by_team)[:id].eq(unit_t[:id]) )
    .where( unit_t[:id]
      .in(
        unit_t
        .project(unit_t[:id])
        .join( alias_(unit_joins_cir_pprfl, :u_cir_pro) )
          .on( u_cir_pro_t[:uid].eq(unit_t[:id]) )  #join player_profiles
        .join( player_t )
          .on( player_t[:id].eq(u_cir_pro_t[:ppr_id]) ) # join players, to player profiles [joined to units]
        .where( u_cir_pro_t[:ppr_pos].eq(position_type) )  # player_id_num CRITERIA (plr_prfls: position_type_eq)
        .group(unit_t[:id])
        .having(Arel.star.count.send(*_rel_to_pos_type_mark) ) )) # quantity of position-type CRITERIA
    .group(unit_t[:id])
    .having(unit_t[:id].count.send(*_rel_to_unit_size_mark) )
  end

  def derived_units_with_pids

    unit_ppos_type_t = Arel::Table.new(:unit_ppos_type)

    unit_t
    .project( unit_t[:id], player_t[:player_id_num] )
    .join( alias_(u_cir_prfl_plyr, :derived_units) )
      .on( Arel::Table.new(:derived_units)[:id].eq(unit_t[:id]) )
    .join( alias_(
            unit_where_pos_eq()
              .project( u_cir_pro_t[:ppr_id] ), # avoids need to (re)join circumstances & player_profiles (unit_joins_cir_pprfl)
            :unit_ppos_type ) )
      .on( unit_ppos_type_t[:uid].eq(unit_t[:id]) )
    .join( player_t )
      .on( player_t[:id].eq(unit_ppos_type_t[:ppr_id]) )
  end


# /////////////  derived units, via units > instances > events > players > player_profiles  ///////////// #

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
    .join( player_profile_t)
      .on( player_profile_t[:player_id].eq(player_t[:id]) )
    .where( event_type_eq_shift
      .and(position_type_eq) )
    .group( unit_t[:id], player_t[:player_id_num] )

    # .where event in [x games] -- temporal data
  end
  # more concisely relevant results——
    # calculation:
      # TOI > 1:00 OR
      # total goals while on ice > 0. ——goals + abs(plus-minus - goals)
        # refinement: goals per TOI calc-- 0.001 < ( goals + abs(plus-minus - goals) )/TOI

  def unit_ids_filter
    instance_t
    .project( instance_t[:unit_id] )
    .join( events_instances_t)
      .on( instance_id_eq )
    .join( event_t )
      .on( event_t[:id].eq(events_instances_t[:event_id]) )
    .where( events_instances_t[:instance_id]
      .in( instance_id_via_count_of_position_type )
      .and(event_type_eq_shift) )
    .group( instance_t[:unit_id], events_instances_t[:instance_id] )
    .having( events_instances_t[:instance_id].count
      .send(*_rel_to_unit_size_mark) )
  end

  def select_instance_ids
    instance_t
    .project( instance_t[:id] ) end

  # instances of players from a team roster, with player count criteria for position-type criteria.
  def instance_id_via_count_of_position_type
    events_instances_t
    .project( events_instances_t[:instance_id] )
    .where( events_instances_t[:event_id]
      .in(event_t
          .project( event_t[:id] )
          .where( event_t[:player_id_num]
            .in(pid_w_plrs_rtrs_w_plr_prfls()
                .where(plr_rtrs_rtr_ids_for_team()
                       .and(position_type_eq) ))
            .and(event_type_eq_shift) )))
    .group( events_instances_t[:instance_id] )
    .having( Arel.star.count.send(*_rel_to_pos_type_mark) )
  end


# ///////////////////////  derived units: helpers  /////////////////////// #

  # select player_id_num; join rosters and profiles
  def pid_w_plrs_rtrs_w_plr_prfls
    player_t
    .project( player_t[:player_id_num] ).distinct
    .join(players_rosters_t).on(
      players_rosters_t[:player_id].eq(player_t[:id]) )
    .join(player_profile_t).on(
      player_profile_t[:player_id].eq(player_t[:id]) ) end

  # players_rosters' roster_id, for rosters' id, for teams' id
  def plr_rtrs_rtr_ids_for_team
    players_rosters_t[:roster_id]
      .in( rosters_join_team()
        .where( team_id_eq ) ) end

  # select rosters' ids, join team
  def rosters_join_team
    roster_t
    .project( roster_t[:id] )
    .join(team_t).on(
      roster_t[:team_id].eq(team_t[:id]) ) end


# ///////////////////////  [table] definitions  /////////////////////// #


  def team_t; Team.arel_table end
  def roster_t; Roster.arel_table end
  def game_t; Game.arel_table end
  def unit_t; Unit.arel_table end
  def circumstance_t; Circumstance.arel_table end
  def players_rosters_t; Arel::Table.new(:players_rosters) end
  def log_entry_t; LogEntry.arel_table end
  def events_instances_t; Arel::Table.new(:events_instances) end
  def event_t; Event.arel_table end
  def instance_t; Instance.arel_table end
  def player_t; Player.arel_table end
  def roster_t; Roster.arel_table end
  def player_profile_t; PlayerProfile.arel_table end
  def games_rosters_t; Arel::Table.new(:games_rosters) end
  def rosters_units_t; Arel::Table.new(:rosters_units) end

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
