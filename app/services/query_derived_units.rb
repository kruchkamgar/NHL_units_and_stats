module QueryDerivedUnits
  # fwd units come in 2 (OT), 3-man units
  # use controller to display fwd units or d
  # use a class to keep DRY

  class DerivedUnits
    include ActiveModel::Serializers::JSON
    # include ActiveModel::Serialization
    attr_accessor :players, :tallies

    def initialize(players, tallies)
      @players, @tallies = players, tallies
    end

    def attributes
      {'players' => nil, 'tallies' => nil}
    end
  end


  def display_units(position_type, team_id: , position_type_mark: )
    sql = query_units(position_type, team_id, position_type_mark)

    units = retrieve_units(sql)
    .eager_load(
      instances: [events: [player_profiles: [:player] ]] )

    units_groups = units
    .group_by do |unit|
      unit.instances.first.events
      .select do |event|
        event.event_type = "shift" end
      .select do |event|
        event
        .player_profiles.any? do |profile|
          profile.position_type == "Forward" end
      end
      .map do |event|
        player = event.player_profiles.first.player
        [player.first_name, player.last_name]
      end
      .sort do |a, b|
        a[1] <=> b[1] end
    end #group_by

    # produce array of totals hashes, standing for the aggregate units
    units_groups
    .map do |plyrs, units|
      unit_tallies =
      units
      .map do |unit|
        unit.tallies.first.attributes
        .reject do |attr|
          attr == "id" ||
          attr == "unit_id" ||
          attr == "created_at" ||
          attr == "updated_at" end
      end
      .inject do |totals, stat_hash|
          stat_hash
          .map do |stat, value|
            [ stat, value + totals[stat] ] end
          .to_h
      end
      DerivedUnits.new(
        plyrs, unit_tallies)
    end #map groups
  end

  def retrieve_units(sql)
    # ApplicationRecord.connection.execute(sql)
    Unit.where("units.id IN " + sql)
  end

# use BETWEEN intead of dynamic comparison operators?
  def query_units(position_type, team_id, position_type_mark, count_of_type_relative_to_mark: ">=", unit_size_mark: 3, unit_size_relative_to_mark: ">=" )
    # at_least_this_many_of_position_type must have number less than than min_unit_size
    <<~SQL
        (SELECT unit_id
        FROM instances
        JOIN events_instances
        ON instance_id = instances.id
        JOIN events
        ON events.id = event_id
        WHERE instances.id IN
          (SELECT instances.id
          FROM instances
          JOIN
            (SELECT instance_id
            FROM events_instances
            WHERE event_id IN
              (SELECT id
              FROM events
              WHERE player_id_num IN (
                SELECT distinct player_id_num
                FROM players
                JOIN players_rosters ON players.id = players_rosters.player_id
                JOIN player_profiles ON players.id = player_profiles.player_id
                WHERE players_rosters.roster_id IN (
                  SELECT distinct rosters.id
                  FROM rosters
                  JOIN teams ON rosters.team_id = teams.id
                  WHERE teams.team_id = #{team_id} )
                  AND position_type = '#{position_type}' )
            AND events.event_type = 'shift' )
            GROUP BY instance_id
            HAVING COUNT(*) #{count_of_type_relative_to_mark} #{position_type_mark} )
          ON instance_id = instances.id )
        AND events.event_type = 'shift'
        GROUP BY unit_id, instance_id
        HAVING COUNT(instance_id) #{unit_size_relative_to_mark} #{unit_size_mark} )
    SQL
  end

end #module QueryDerivedUnits
