
class UnitsController < ApplicationController

include QueryDerivedUnits
  def index
    # for the current day-- incl date parameter -- breakout just for readability?
  end

  def show_units

    # @units = Unit.joins(:tallies).order("tallies.plus_minus + 0 DESC").limit(5)
    #
    # render json: @units
    team_id = unit_params[:team_id]

    @derived_units =
    display_units("Forward", team_id: team_id.to_i, position_type_mark: 3)

    render json: @derived_units.as_json
  end

  def show_unit
    # unit_id = unit_params[:id]
    #
    # unit = Unit.find(unit_id)
    # render json: unit.to_json
  end

  def utility_json
  end

private
  def unit_params
    params.permit(:team_id, :position_type_mark, :role)
  end

end

# Unit.order(created_at: :desc).limit(3).
# to_json(
#   include: [instances:
#     { include: [:events] }
# ] )
