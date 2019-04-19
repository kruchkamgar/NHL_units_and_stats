
module QueryDerivedUnits
  # fwd units come in 2 (OT), 3-man units
  # use controller to display fwd units or d
  # use a class to keep DRY

  class DerivedUnits
    include ActiveModel::Serializers::JSON
    # include ActiveModel::Serialization
    attr_accessor :players, :tallies

    def self.team_players(team_id)
      @@team_players =
      Player
      .joins(rosters: [:team])
      .where(teams: {team_id: team_id}).distinct
      .group_by do |plyr|
        plyr.player_id_num end
    end

    def initialize(players, tallies)
      @players, @tallies = player_data(players), tallies
    end

    def player_data(players)
      players
      .map do |plyr_id_num|
        @@team_players[plyr_id_num].first.last_name end
    end

    def attributes
      {'players' => nil, 'tallies' => nil}
    end
  end

include ComposedQueries
include Utilities
  def display_units(position_type, team_id: , position_type_mark: , unit_size_mark: 3)

    @team_id, @position_type, @position_type_mark, @unit_size_mark = team_id, position_type, position_type_mark, unit_size_mark

    # set hash of team's players
    DerivedUnits.team_players(@team_id)

    units_rows = retrieve_units_rows_by_param()

    rows_grouped_by_unit = units_rows
    .group_by do |unit| unit["id"] end

    units = Unit.where(id: [ rows_grouped_by_unit.keys ]).includes(:stats)

    unit_groups_array = rows_grouped_by_unit.to_a

    units_grouped_by_pids =
    units
    .group_by.with_index do |unit, i|
      unit_groups_array[i].second
      .map do |hash|
        hash["player_id_num"]
      end.sort
    end

    units_grouped_by_pids
    .map do |plyrs, units|
      unit_tallies =
      units
      .map do |unit|
        unit.stats.first.attributes
        .reject do |attr|
          attr == "id" ||
          attr == "unit_id" end
      end
      .inject do |totals, stat_hash|
        # map over stat_hash for each unit, return new hash to act as new 'totals'
        stat_hash
        .map do |stat, value|
          if value.class == String
            Array.[](
              stat, TimeOperation.new(:+, totals[stat], value).result )
          else
            Array.[](
              stat, (value || 0) + (totals[stat] || 0) ) end
        end
        .to_h #.map
      end #.inject

      unit_tallies["TOI"] = TimeOperation.new(:+, "00:00", unit_tallies["TOI"]).seconds
      [plyrs, unit_tallies]
    end #map units_grouped_by_pids
    .sort do |a, b|
      (b.second["plus_minus"] || 0) <=> (a.second["plus_minus"] || 0 ) end
    .map do |derived_unit|
      DerivedUnits.new( *derived_unit ) end

  end #display_units

end #module QueryDerivedUnits
